# Plan de implementación local — OCR keyless

**Estado documental:** ACTIVE
**Fecha:** 2026-10-02; Task0 resuelto el 2026-10-05
**Diseño aceptado; revisado el 2026-10-07. Task0 y Task1 aprobados en local el 2026-10-05; Task1b (`X-Ocr-Page-Count`) **`PASS_LOCAL_SLICE` el 2026-10-07** tras revisión independiente (vectores HMAC recalculados aparte, 65 pruebas con emulador); deja el requisito 2b para Task3. Task2 aprobado en local el 2026-10-06. La evidencia del ledger es del emulador local, no exactly-once de producción. TaskR: **`PASS_LOCAL_SLICE` el 2026-10-07** tras revisión independiente (tope de decode vía parche pdf-lib + AsyncLocalStorage, worker descartable con heap acotado al plan Free, semáforo de 1 worker, plazos cola/arranque→ready/parseo separados, `CERTIFICATE_IMPORT_PDF_BUSY` HTTP 429 en `confirm()`). Evidencia: 116 pruebas backend, 42 Flutter, XRef N=20M +73 MiB de pico, 3 concurrentes +28 MiB, heap retenido 0, bombas de inflate rechazadas. Task1b quedó implementado en local el 2026-10-07, pendiente de revisión independiente: no es `PASS_LOCAL_SLICE` y no autoriza Task3. Task3 reformulado sin parseo PDF en el proxy: la propuesta `PASS_PROPOSAL_WITH_STOP_GATE` queda reemplazada y el STOP de contención se traslada a TaskR. Task3 **`PASS_LOCAL_SLICE` el 2026-10-07** tras revisión independiente (98 pruebas con emulador; headers case-insensitive; firma del digest declarado antes de leer el cuerpo; `recoverPlanned` con fence nuevo). Task4 **`PASS_LOCAL_SLICE` el 2026-10-07** tras revisión independiente (180 pruebas backend, 100 del proxy con emulador, e2e real provider → proxy → ledger; decisión (b) para lease vigente; firmante propio con vectores dorados; secreto HMAC ≥ 32 bytes en ambos lados; `OCR_MODE` y https obligatorios en producción; deadline absoluto de 40 s). Task5 **`PASS_LOCAL_SLICE` el 2026-10-07** tras revisión del orquestador: entrypoint `src/main.ts` en `0.0.0.0:$PORT` con config validada que falla cerrado (rechaza emulador, `demo-` y `GOOGLE_APPLICATION_CREDENTIALS`), drenado con SIGTERM ajustado a la ventana de 10 s de Cloud Run (default 8 s, máximo 9 s), cold start local ~200 ms, 180 pruebas del proxy; docs sincronizados y runbook `docs/guides/ocr-proxy-preprod-infra.md`. **Retención resuelta (decisión (a), 2026-10-07):** todo documento del ledger (`operations`, `nonces`, `quota` bajo `ocrLedgers/{entorno}/…`) lleva `expireAt` de tipo Firestore `Timestamp`, igual a su purga lógica (operación `issuedAt`+8 d; nonce `receivedAt`+540 s; cuota máx(guardado, D+9 d)). Se reescribe en cada transición, nunca se acorta y ninguna decisión lógica lo lee; `write()` falla cerrado sin él. 193 pruebas del proxy (13 nuevas contra el emulador, tipo `timestampValue` verificado). La política TTL sobre `expireAt` se aplica después del despliegue (runbook, Fase 2.3). **Parte local completa. Nada desplegado.** No desplegado.**

## Revisión 2026-10-07 — qué cambia y por qué

1. **El riesgo PDF vive primero en Render.** `assertCertificateImportPdf()` ya ejecuta
   `PDFDocument.load` de pdf-lib sobre el PDF no confiable dentro del proceso API de Render
   (`certificate-import-files.service.ts`, en `confirm()`) y otra vez en el proveedor de OCR
   (`google-vision-certificate-ocr.provider.ts`). Un PDF bomba afecta a la API de todos los
   usuarios antes de llegar al proxy. Aislar el parser solo en el proxy protegía un punto aguas abajo.
2. **Contención en Render (TaskR).** Un solo worker descartable a la vez, dimensionado para
   Render Free (512 MiB, 0,1 CPU). El tope de descompresión sigue dentro del worker
   (`DecodeStream.ensureBuffer`, 1/2 MiB). TaskR después fue `PASS_LOCAL_SLICE`. Ese corte no incluye Task1b.
3. **El proxy no parsea PDF (Task3 reformulado).** Render, que ya validó y contó páginas, envía
   `X-Ocr-Page-Count` firmado (Task1b). El proxy reserva esas páginas, llama a Vision con
   `pages: [1..N]` y exige cobertura exacta y `totalPages == N`. Un PDF que miente cuesta como
   máximo las N ≤ 5 páginas pedidas. Se eliminan pdf-lib, el proceso hijo y el presupuesto de
   memoria del proxy; 512 MiB alcanza para cuerpo de 10 MiB y JSON de 16 MiB.
4. **429 de plataforma ≠ cuota.** Con max instances 1, Cloud Run puede responder 429 sin el
   envelope JSON del proxy. Solo `{version:"v1",code:"QUOTA"}` válido mapea a
   `CERTIFICATE_IMPORT_OCR_QUOTA`; cualquier 429/5xx/504 sin envelope válido es `UNAVAILABLE`.
   Reintentar es seguro porque el ledger impide una segunda llamada Vision tras `CALLING`.
5. **Gates de org verificados (lectura, 2026-10-07).** `iam.allowedPolicyMemberDomains`:
   allowAll (sin DRS). `run.managed.requireInvokerIam`: no impuesta. `gcp.resourceLocations`:
   allowAll. Invocación pública vía `run.googleapis.com/invoker-iam-disabled` es viable sin
   tocar políticas. Re-verificar en el proyecto de producción cuando se identifique.
6. **Alternativa API key evaluada y descartada.** La org permite API keys estándar (solo bloquea
   las vinculadas a SA), pero Vision solo tiene cuotas por minuto (1800/min por defecto), sin tope
   diario. Una key filtrada expone del orden de US$19k/día con la cuota por defecto; un HMAC
   filtrado queda acotado a 400 páginas/día (~US$0,60). Decisión humana: seguir con el proxy.

## Goal

Preparar un proxy HTTPS HMAC en Cloud Run con ADC y ledger Firestore solo metadata,
conservando Render, evidencia privada y revisión humana. Implementar únicamente después
de autorización local explícita y respetar los gates de infraestructura independientes.

## Architecture

Seguir el [diseño aceptado](2026-10-02-vision-keyless-design.md): contrato binario interno
`POST /v1/ocr`; 10 MiB, PDF1–5, respuesta JSON UTF-8 ≤16 MiB; HMAC/replay durable;
400 páginas por día UTC compartidas por entorno; no caché de OCR ni archivos.
Commit `CALLING` confirmado antes de Vision fuera de transacciones. Incertidumbre y respuesta
perdida de `COMPLETE` van a manual, sin segunda llamada. Virginia `us-east4`; Vision endpoint US.

## Tech Stack

Actual backend: Node24, Nest11, TypeScript6, pnpm10, ConfigService/Joi, BullMQ,
`@google-cloud/vision` y `pdf-lib`; no dependencia Firestore instalada actualmente.
Servicio remoto: tecnología compatible propuesta, ubicación/framework/package y versión
Firestore pendientes de **Task0**; no se crea ningún repo, paquete ni scaffold con este plan.
Firestore Standard regional, Secret Manager y Cloud Run son dependencias futuras aprobadas
como diseño, no servicios ya configurados.

**Execution required skills (futuro):** `executing-plans`, `test-driven-development`,
`verification-before-completion` y revisión de seguridad/backend con reglas SACDIA resueltas.
No aplicar este plan por leerlo. No commits, builds, installs, cloud writes o smoke live implícitos.

## Alcance y evidencia actual

Rutas existentes relativas al workspace; deben revalidarse con Graft antes de cada slice:

- `sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.provider.ts` — seam actual.
- `sacdia-backend/src/certificate-bulk-imports/ocr/google-vision-certificate-ocr.provider.ts` y `sacdia-backend/src/certificate-bulk-imports/ocr/google-vision-certificate-ocr.provider.spec.ts` — ADC/RPC.
- `sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.parser.ts` y `sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.parser.spec.ts` — parsing completo.
- `sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.queue.ts` — payload.
- `sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.processor.ts` y `sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.processor.spec.ts` — worker.
- `sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.service.ts` y `sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts` — ownership/enqueue/persistencia.
- `sacdia-backend/src/certificate-bulk-imports/certificate-import-pdf.ts` y `sacdia-backend/src/certificate-bulk-imports/certificate-import-pdf.spec.ts` — PDF.
- `sacdia-backend/src/certificate-bulk-imports/certificate-import-files.service.spec.ts` — sellado.
- `sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.module.ts` — DI.
- `sacdia-backend/src/config/env.validation.ts` y `sacdia-backend/src/config/env.validation.spec.ts` — Joi.

No se cambia API pública, schema, Flutter, admin, R2 ownership o aprobación institucional.

## Task0 — resolver gates antes de escribir runtime

1. Capturar HEAD/index y diff de rutas propias; preservar todos los cambios concurrentes.
   Leer AGENTS/CLAUDE, canon de feature/API y obtener spans Graft actuales.
2. Presentar ubicación/framework del proxy. Candidato **no elegido ni creado**:
   `sacdia-ocr-proxy/`, servicio Node/Nest compatible, paquete autónomo sin heredar todo el backend.
   Si se elige otro layout, actualizar los paths candidatos del plan antes de crear archivos.
3. Definir shared contract/helpers sin duplicar validación PDF/HMAC: paquete compartido o extracción
   mínima requiere decisión de layout. No copiar el backend completo ni introducir acceso DB/R2 al proxy.
4. Resolver `operationId/issuedAt` estables por archivo. Payload actual solo tiene userId/batchId;
   job se elimina al completar. Documentar identidad sellada y contexto recuperable entre reintentos,
   reencolado y reinicios, sin usar nuevo UUID por intento ni reset por rotación de secreto.
   Si exige nuevo schema, endpoint o persistencia de negocio, STOP para autorización específica.
5. Congelar gramática HMAC, nombres de headers, envelope y códigos internos; verificar mapping contra
   catálogo actual. `OCR_MAX_PAGES_PER_ENV_PER_DAY` default400 es nombre candidato, positivo/acotado.
6. Decidir versiones exactas y licencia/audit de nuevas dependencias antes de instalar; audit online
   requiere autorización de metadatos. Sin instalar en este paso.

**Salida:** contrato/layout/contexto operativo revisados y aprobación de slice local. Ningún gate
se resuelve suponiendo que acceso IAM, Redis o configuración remota ya funcionan.

## Task0 — resolución local (2026-10-05)

Evidencia de trabajo: meta-repo `development` @ `6845467e29d84d07e2558e4d10f12fe4a211faea`.
`sacdia-backend` es repo anidado ignorado, rama `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`,
con cambios concurrentes de investidura que este slice no toca. Node local `v24.13.1`.

### Layout y framework

Paquete autónomo `sacdia-ocr-proxy/` en el meta-repo. No es repo git nuevo, no vive dentro de
`sacdia-backend` y no hereda Nest, Prisma, R2 ni BullMQ. Este slice no abre socket ni registra
rutas. Nest y el handler HTTP quedan para Task3, y solo si entonces se aprueba esa dependencia.

Runner: `node:test` con el type stripping de Node 24. Jest sigue siendo candidato no elegido:
instalarlo violaría el gate de dependencias. Cero dependencies y cero devDependencies.
Typecheck con el TypeScript ya instalado en `sacdia-backend` (`typescript` ^6.0.3), sin instalar
otra copia. Lint con el ESLint ya instalado allí, sin `--fix` y sin `npm audit` (no autorizado).

Comandos de este paquete:

```sh
node --test --test-reporter=spec sacdia-ocr-proxy/test/*.spec.ts
sacdia-backend/node_modules/.bin/tsc --noEmit --pretty false -p sacdia-ocr-proxy/tsconfig.json
sacdia-backend/node_modules/.bin/eslint --no-fix -c sacdia-ocr-proxy/eslint.config.mjs sacdia-ocr-proxy/src sacdia-ocr-proxy/test
```

El contrato vive en `sacdia-ocr-proxy/src`. Render clona solo `sacdia-backend`, así que Task4 no
importa el proxy ni crea un tercer paquete: el backend tiene su propio firmante
(`src/certificate-bulk-imports/ocr/ocr-proxy-signer.ts`, `node:crypto`). La equivalencia queda
fijada por los vectores dorados imagen/1 y pdf/5, repetidos en las dos suites. Si un vector
difiere, fallan ambas.

### operationId e issuedAt

No hace falta schema, endpoint público ni columna nueva.

- `operationId` es el `file_id` ya persistido. Opaco, estable entre reintento BullMQ, reinicio y
  reencolado. No es un UUID nuevo por HTTP ni cambia al rotar el secreto HMAC.
- `issuedAt` es `confirmed_at` en forma canónica UTC `YYYY-MM-DDTHH:mm:ss.sssZ`. `confirm()`
  reclama la fila con `updateMany` y predicado de compare-and-set sobre `file_id`,
  `upload_status`, `object_key`, `confirmed_at`, `staging_key` y `size_bytes`. La fecha escrita
  sale del snapshot (`existing.confirmed_at ?? new Date()`). Si otra confirmación ya ganó, esta
  no escribe: relee el sello y devuelve ese mismo `object_key` y `confirmed_at`. El sello propio
  se borra solo cuando la relectura demuestra que no quedó referenciado. Un error de commit
  ambiguo conserva la evidencia. Si al entrar la fila ya está `CONFIRMED` con `object_key` y
  `size_bytes`, se devuelve ese sello sin copiar de nuevo. El único escritor de `object_key`
  en este dominio es ese `confirm()`.
- El worker vuelve a leer el archivo activo confirmado desde Postgres. El payload `{ userId, batchId }`
  y `jobId=certificate-ocr-{batchId}` no son la identidad: `removeOnComplete: true` borra el job.
- `userId` no viaja al proxy. `deriveOcrOperation` no acepta usuario, kid ni secreto.
- `confirmed_at` nulo o `file_id` que no sea UUID canónico falla cerrado. Task4 no puede estampar
  `Date.now()`.
- Desactivar un archivo y subir otro crea otro `file_id` y otra operación. Cada intento sella
  en `fileId-<uuid>`, imágenes incluidas. Una confirmación perdedora no sustituye el
  `object_key`, el `confirmed_at` ni los bytes del objeto ganador: su copia queda en otra key
  y se borra cuando la relectura demuestra que no quedó referenciada. El mismo `operationId`
  con otro SHA-256 es conflicto de ledger (Task2), no un id nuevo para eludirlo.
- La ventana de siete días de la operación es admisión (Task2). La firma solo exige `issuedAt`
  canónico y un `timestamp` de intento dentro de ±120 segundos.

### Gramática HMAC v1

Cuerda canónica UTF-8, un campo por línea, terminada en `\n`, en este orden fijo:
`v1`, `POST`, `/v1/ocr`, entorno, `kid`, `operationId`, `issuedAt`, MIME, longitud decimal,
cantidad de páginas decimal (enmienda Task1b), timestamp Unix en segundos, nonce, SHA-256 hex del cuerpo. Sin trim y sin aceptar `\r` o `\n`
dentro de un campo. HMAC-SHA256, firma en hex minúscula de 64 caracteres, comparación
`timingSafeEqual`. El secreto de runtime son al menos 32 bytes. En el backend el valor de
`OCR_PROXY_SECRET` es base64 estándar de esos bytes (`openssl rand -base64 32`); se valida el
largo decodificado. El llavero del proxy guarda los bytes, no el texto base64. Firmar o
verificar con menos de 32 bytes falla cerrado. Los vectores de 15 bytes (`test-key-ocr-v1`)
quedan solo como historia, calculados con `createHmac` y rechazados por `signOcrRequest` y
`verifyOcrRequest`.

Headers firmados, exactamente una vez. Los nombres son case-insensitive: se comparan en
minúsculas y la capitalización de la tabla es la forma canónica, no un requisito. Un duplicado,
aunque solo cambie mayúsculas (`X-Ocr-Nonce` y `x-ocr-nonce`), o cualquier otro `x-ocr-*` en
cualquier capitalización, rechaza con `INVALID_CONTRACT`. La cuerda canónica firma valores, no
los nombres. `Host`, `Content-Length` y `Transfer-Encoding` no entran en la firma.
`Content-Length` no decide cuántos bytes se leen ni cuántos se hashean.

| Header | Gramática |
|---|---|
| `X-Ocr-Version` | `v1` |
| `X-Ocr-Env` | `^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$` y el entorno único del proceso |
| `X-Ocr-Kid` | `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`, presente en el llavero de ese entorno |
| `X-Ocr-Operation-Id` | `^[A-Za-z0-9][A-Za-z0-9_-]{15,127}$` |
| `X-Ocr-Issued-At` | `YYYY-MM-DDTHH:mm:ss.sssZ` real; `toISOString()` debe devolver el mismo texto |
| `X-Ocr-Content-Type` | `image/jpeg`, `image/png`, `image/webp`, `application/pdf` |
| `X-Ocr-Content-Length` | decimal sin ceros a la izquierda, 1..10485760, igual a los bytes leídos |
| `X-Ocr-Page-Count` | (Task1b) `1`..`5`, sin ceros a la izquierda; imagen exige `1`; PDF lleva el conteo validado por Render |
| `X-Ocr-Timestamp` | segundos Unix, sin ceros a la izquierda, sesgo ±120 s |
| `X-Ocr-Nonce` | `^[0-9a-f]{32,64}$` |
| `X-Ocr-Content-SHA256` | `^[0-9a-f]{64}$` |
| `X-Ocr-Signature` | `^[0-9a-f]{64}$` |

Transporte: sin redirects (301, 302, 303, 307, 308). `Content-Encoding` ausente o `identity`.
`Content-Type` HTTP ausente o `application/octet-stream`. No se descomprime. Tope de lectura
10 485 760 bytes, no elevable por el caller. Orden: formato y HMAC del digest declarado, después
lectura acotada, después digest real. Recién entonces podría existir PDF o Vision; este slice no
los llama.

Respuesta 200: JSON UTF-8 `{"version","operationId","pageCount","pages":[{"pageNumber","text"}]}`,
páginas 1..N exactamente una vez y en orden, N entre 1 y 5. Documento todo vacío rechazado.
Tope 16 777 216 bytes del JSON completo; el exceso falla entero, sin truncar ni protobuf.

Error: `{"version","code","requestId"}`. `requestId` es 32 hex y no puede copiar `operationId`,
nonce o digest cuando se conocen. Códigos internos y adaptación Render, sin endpoint nuevo:

| Código interno | HTTP | Código Render existente |
|---|---|---|
| `UNAUTHORIZED`, `FORBIDDEN`, `UNAVAILABLE`, `DISCONNECTED` | 401, 403, 503, 503 | `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` |
| `UNSUPPORTED_TYPE` | 400 | `CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE` |
| `PAYLOAD_TOO_LARGE` | 413 | `CERTIFICATE_IMPORT_OCR_FILE_TOO_LARGE` |
| `PDF_TOO_MANY_PAGES`, `PDF_ENCRYPTED`, `PDF_INVALID` | 400 | el mismo nombre `CERTIFICATE_IMPORT_PDF_*` |
| `INVALID_CONTRACT`, `ENCODED`, `EMPTY_DOCUMENT`, `CONFLICT`, `RESPONSE_TOO_LARGE`, `UNCERTAIN` | 400, 400, 400, 409, 504, 504 | `CERTIFICATE_IMPORT_OCR_FAILED` |
| `PAGE_COUNT_MISMATCH` (Task3) | 502 | `CERTIFICATE_IMPORT_OCR_FAILED`; post-`CALLING`, terminal, sin segunda llamada |
| `QUOTA` | 429 | `CERTIFICATE_IMPORT_OCR_QUOTA` |
| Sin envelope válido (429/5xx/504 de plataforma Cloud Run) | cualquiera | `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`; reintento BullMQ seguro por ledger |

`OCR_MAX_PAGES_PER_ENV_PER_DAY`: entero 1..400. Ausente significa 400. `0`, negativo, fracción,
string o valor mayor que 400 es inválido y no significa ilimitado. El contador durable es Task2.

Dependencias nuevas: ninguna. No hay SDK de Firestore, Vision, Nest ni Jest en este paquete.

## Estrategia de entrega y riesgo de revisión

Estimación orientativa futura: 900–1600 líneas entre runtime y pruebas; riesgo **alto >400 líneas**.
Recomendados slices autónomos encadenados: (1) contrato/HMAC, (2) ledger/admisión,
(1b) enmienda de conteo, (R) contención PDF en Render, (3) handler/Vision, (4) adaptador Render,
(5) docs/verificación. Orden sugerido desde 2026-10-07: TaskR → Task1b → Task3 → Task4 → Task5. Antes de aplicar, el coordinador
acuerda encadenado o excepción explícita de tamaño. No obliga a PRs/commits sin autorización.
No activar remotamente slices incompletos: el modo remoto queda apagado hasta revisión conjunta.

## Disciplina RED/GREEN para cada tarea

Agregar un caso que hoy falle, ejecutar solo esa prueba y registrar FAIL causal (no error de setup);
implementar lo mínimo, repetir y registrar PASS; luego suite relacionada y lint/noEmit acotados.
Todos los comandos abajo son **futuros**, no ejecutados durante creación de estos documentos.
No utilizar `pnpm run lint` porque aplica `--fix` global, ni `pnpm build`/`nest build`.

Comandos existentes backend, desde `sacdia-backend/`:

```sh
pnpm exec jest src/certificate-bulk-imports/ocr/google-vision-certificate-ocr.provider.spec.ts --runInBand
pnpm exec jest src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts --runInBand
pnpm exec jest src/certificate-bulk-imports/ocr/certificate-ocr.processor.spec.ts --runInBand
pnpm exec jest src/config/env.validation.spec.ts --runInBand
pnpm exec jest certificate-bulk-imports certificate-import env.validation.spec --runInBand
```

Proxy: runner resuelto en Task0, `node --test`, no Jest. Comando en la sección «Task0 — resolución local».

## Task1 — contrato puro, firma y límites (slice1)

**Paths candidatos proxy:** `sacdia-ocr-proxy/src/ocr/ocr-contract.ts`, `sacdia-ocr-proxy/src/auth/ocr-signature.ts`,
`sacdia-ocr-proxy/src/ocr/bounded-body.ts`; tests `sacdia-ocr-proxy/test/ocr-contract.spec.ts`, `sacdia-ocr-proxy/test/ocr-signature.spec.ts`.
Helpers compartidos se ubican solo tras resolver Task0.

1. **RED:** tests canonicalización conocida; firma alterando cada campo, bytes, MIME, entorno,
   longitud, método/path y opissuedAt; headers duplicados, kid desconocido, nonce corto, skew±120.
2. Ejecutar cada spec → FAIL por función/regla ausente; incluir vectores independientes del signer.
3. Implementar contrato estricto, HMAC constant-time, reader sin compresión y límite10MiB;
   hash real antes de parser, no Content-Length de confianza ni redirects.
4. **GREEN:** límite exacto/byte extra, chunked body, desconexión, rechazo sin PDF ni SDK invocado;
   no body/headers/secrets en logs. Firma no puede separarse del payload.
5. Verificar serialization JSON16MiB incluyendo envelope, UTF-8 multibyte, no truncation/protobuf.

**Salida autónoma:** contrato y primitives probados; no endpoint habilitado ni almacén en memoria
usado como protección durable. Test fake solo es un double, nunca la solución de producción.

**Progreso 2026-10-05:** revisión final local `PASS_LOCAL_SLICE`. Task0 y Task1 aprobados. 28 pruebas
del proxy y 23 del backend. La copia perdedora no modifica ni elimina el objeto ganador; un commit
ambiguo conserva la evidencia. Esta aprobación no autoriza Task2, despliegue ni infraestructura.

### Task1b — enmienda `X-Ocr-Page-Count` (2026-10-07, implementada en local, pendiente de revisión)

Reabre solo el contrato, no las garantías aprobadas. Paths: `ocr-contract.ts`, `ocr-signature.ts`
y sus specs. Se mantiene `v1`: nada está desplegado ni tiene consumidores.

1. **RED:** firma alterando solo el conteo; header ausente, duplicado, `0`, `6`, `05`, no decimal;
   imagen con conteo distinto de `1`; vectores canónicos actualizados e independientes del signer.
2. **GREEN:** campo en la cuerda entre longitud y timestamp; validación de gramática y regla imagen=1.
3. Repetir las 28 + 23 regresiones de Task0/Task1 y las de Task2 que toquen el contrato.
   El ledger reserva el conteo firmado; mismo `operationId` con otro conteo es `CONFLICT`.

**Progreso 2026-10-07:** implementado en local. Pendiente de revisión independiente. No es
`PASS_LOCAL_SLICE`. No autoriza Task3, Task4 ni despliegue.

RED, antes de reconocer el header: la cuerda canónica no tenía el conteo entre la longitud y el
timestamp; `OCR_HEADERS.pageCount` era `undefined`; un PDF de 5 firmado de forma independiente no
verificaba; alterar el conteo devolvía `INVALID_CONTRACT` y no `UNAUTHORIZED`; `admitOperation`
admitía un resultado sin `pageCount`. El firmante no rechazaba `0`. Tras cablear el header y antes
de la gramática, `"0"` y una imagen con `"2"` verificaban en verde y el firmante seguía aceptando
`0`, `6` y una imagen con `2`.

GREEN: `parseOcrPageCount` exige `^[1-5]$`; imagen = 1; PDF = 1..5. La cuerda v1 inserta ese
decimal entre la longitud y el timestamp. `verifyOcrRequest` devuelve `pageCount`.
`admitOperation` copia solo ese valor al ledger y no llama si la verificación no trae un entero
1..5. Mismo `operationId` con otro conteo firmado: `CONFLICT` en el doble y en el emulador
`127.0.0.1:8099`, proyecto `demo-ocr-local`; la reserva queda en 5. Quitar cada guarda (campo
canónico, header firmado, regex, regla de imagen, rechazo del firmante, conteo no firmado o
`?? 1`) hizo fallar su prueba; el fuente se restauró.

65 pruebas del proxy, 0 fallos, incluida la integración del emulador. `tsc --noEmit` exit 0.
ESLint `--no-fix` exit 0, 0 errores; queda un warning previo en `expectSilent` (`eslint-disable
no-console` sin uso). Emulador detenido y `8099` libre. Sin endpoint, handler, Vision, cambios en
`sacdia-backend`, build, commit ni despliegue.

Vectores HMAC-SHA256 independientes, secreto `test-key-ocr-v1`, cuerpo `synthetic certificate`,
SHA-256 `97f9d8301938ef5542f5ac8023d73f35749811eddc5a06844dd82433fe7b6de0`. Imagen, conteo `1`:
`ef8af7bd363e2ea8668a71db8b03a825e52b8a1d9a913408b7dbafc808d11dbd`. PDF, conteo `5`:
`a3a278d6c6bbda80cffe1b61322ee75bf887c28ddfc033dd65b75d02c9a093f2`.

## Task2 — ledger Firestore metadata y cuota (slice2)

**Paths candidatos:** `sacdia-ocr-proxy/src/ledger/ocr-ledger.port.ts`, `sacdia-ocr-proxy/src/ledger/firestore-ocr-ledger.ts`,
`sacdia-ocr-proxy/src/ocr/ocr-admission.ts`; tests `sacdia-ocr-proxy/test/ocr-ledger.spec.ts`, `sacdia-ocr-proxy/test/ocr-admission.spec.ts` y
`sacdia-ocr-proxy/test/firestore-ocr-ledger.integration.spec.ts` para emulator aislado futuro autorizado.

1. **RED:** dos workers compiten por mismo opid/nonce; solo uno admite. Mismo opid distinto
   digest/MIME/length/issuedAt falla; dos entornos no comparten secretos ni contadores.
2. FAIL verificado; implementar transacciones metadata y fence, no Vision dentro callback.
3. **RED/GREEN:** callback repetido, commit ambiguo, relectura inconclusa, lease viejo, store caído;
   ningún caso incierto llama RPC. Confirmar durable `CALLING` antes de external side effect.
4. **RED/GREEN:**400 exactas, 401 rechazo completo, imagen 1, PDF5 reserva 5, retry reserva una vez,
   día UTC cruzado no duplica reserva; configuración 0/negativa/inválida nunca fail-open.
5. **RED/GREEN:** timestamp futuro puede aceptar nonce hasta 240 s desde recepción; conservarlo
   ≥5 min y después de ventana. Operación 7 días, ledger ≥8 días; docs vencidos pero no purgados siguen
   reglas lógicas. Nunca usar TTL/delete para decidir autenticación o reset de idempotencia.
6. Tests reales de transacción contra emulator exclusivo, con setup/teardown acotado y sin cloud;
   no basta mock para demostrar atomicidad. Instalación/start emulator requieren permiso futuro.
7. Verificar schema metadata sin texto/archivo/UUIDusuario/email/URL/objectKey ni índices excesivos.
   Costos TTL/indexes medidos como conteos, no factura exacta inventada.

**Salida:** port durable probado, estados PLANNED/CALLING/COMPLETE/UNKNOWN y límites de garantía.
No crear DB/reglas/IAM/TTL remotos en esta tarea.

**Progreso 2026-10-06:** aprobado en local. No es `PASS_LOCAL_SLICE`. La evidencia sigue siendo el emulador local. Esta nota no reabre el slice.
Dependencia única `@google-cloud/firestore@9.3.1` y lock en `sacdia-ocr-proxy`. Emulador
`cloud-firestore-emulator` 1.22.0, SHA-256
`9b6498b7f62714d67f48f59b3818883cd682dbcd46b9f59511de81c97bb5166c`, solo
`127.0.0.1:8099`, proyecto `demo-ocr-local`. El `--help` del jar lista `CLOUD_FIRESTORE` y
`STANDARD`, pero el conversor rechaza esos valores; el proceso usa `firestore-native` y
`standard`. El cliente valida loopback y proyecto `demo-` antes de construirse, fija
`FIRESTORE_EMULATOR_HOST` y `GCLOUD_PROJECT`, y usa `InertEmulatorAuth`: no construye
`GoogleAuth`, no busca ADC y no renueva tokens. `fetch` solo acepta `http://127.0.0.1`
con `Bearer owner` estático. El harness aborta si 8099 ya tiene listener y solo marca
listo el proceso cuyo pid es el listener. Aprobado en local; el slice queda cerrado.

`PLANNED` puede conservar la reserva si `confirmCalling` falla. No hay efecto externo sin
`CALLING` confirmado y no se reserva dos veces. El nonce se retiene cinco minutos después
de su vencimiento lógico de 240 segundos. La purga no borra antes de ese umbral ni usa el
borrado como autenticación.

Las 13 pruebas del emulador cubren concurrencia, replay, commit ambiguo con relectura real,
fence viejo, estados, cuota 400/401, PDF que no se parte, retry entre días UTC, entornos
aislados y puerto cerrado. Los dobles de `ocr-admission.spec.ts` no prueban atomicidad.
El emulador no replica todas las garantías de producción: no es un sustituto transaccional
completo, un lock puede tardar hasta 30 segundos, no exige índices compuestos y no aplica
todos los límites de producción, incluido el tamaño de transacción.
[Conectar el emulador](https://firebase.google.com/docs/emulator-suite/connect_firestore).
Sin Vision, handler remoto, Render, infraestructura, commit ni despliegue.

## Ejemplos TDD mínimos — orientativos, no creados ni ejecutados

Task0 debe congelar estos ports/fixtures antes de usarlos. Son tests completos de comportamiento,
no código de producción. El fixture de firma usa solo datos sintéticos y una clave de test;
el fixture de admisión es unitario y no sustituye el test de transacción contra emulator.
Primero disponer del harness aprobado y obtener FAIL por regla ausente, no por import inexistente.

Archivo candidato `sacdia-ocr-proxy/test/ocr-signature.spec.ts`; port/harness candidatos
`sacdia-ocr-proxy/test/support/ocr-fixture.ts`, `sacdia-ocr-proxy/src/auth/ocr-signature.ts`:

```ts
import { createSignatureFixture } from './support/ocr-fixture';

describe('firma del cuerpo real', () => {
  it('rechaza bytes alterados aunque los headers firmados no cambien', async () => {
    const fixture = createSignatureFixture();
    const body = Buffer.from('synthetic certificate');
    const request = fixture.signRequest(body);
    await expect(fixture.authenticate(request, body)).resolves.toBe(true);
    const tampered = Buffer.from(body);
    tampered[0] ^= 1;
    await expect(fixture.authenticate(request, tampered)).resolves.toBe(false);
    expect(fixture.visionCallCount()).toBe(0);
  });
});
```

Archivo candidato `sacdia-ocr-proxy/test/ocr-admission.spec.ts`; port candidato
`sacdia-ocr-proxy/src/ocr/ocr-admission.ts` y harness del mismo archivo support:

```ts
import { createAdmissionFixture } from './support/ocr-fixture';

describe('cuota diaria compartida del entorno', () => {
  it('admite 400 páginas, no duplica el retry y rechaza la página 401', async () => {
    const fixture = createAdmissionFixture({ limit: 400, day: '2026-10-02' });
    for (let n = 0; n < 400; n += 1) {
      await expect(fixture.reserve({ operationId: `op-${n}`, pages: 1 }))
        .resolves.toBe('ADMITTED');
    }
    await expect(fixture.reserve({ operationId: 'op-0', pages: 1 }))
      .resolves.toBe('ALREADY_RESERVED');
    await expect(fixture.reserve({ operationId: 'op-400', pages: 1 }))
      .resolves.toBe('QUOTA');
    expect(await fixture.reservedPages()).toBe(400);
    expect(fixture.visionCallCount()).toBe(0);
  });
});
```

## TaskR — contención PDF en Render (2026-10-07, worker descartable, pendiente de revisión)

Protege la API de Render, que hoy ejecuta pdf-lib sin aislamiento. Es independiente del proxy
y puede ir antes que Task3. **Paths:** `sacdia-backend/src/certificate-bulk-imports/certificate-import-pdf.ts`
(padre, sin pdf-lib), `certificate-import-pdf-parse.ts`, `certificate-import-pdf.worker.ts`,
`certificate-import-pdf-decode-cap.ts`, `certificate-import-pdf-bounds.ts`,
`certificate-import-pdf.spec.ts`; fixtures en `test/certificate-bulk-imports/`.

Los pasos 1–5 describen el pre-escaneo rechazado. El estado vigente está en las notas de progreso.

1. **Pre-escaneo antes de `PDFDocument.load`:** localizar cada objeto stream y su diccionario;
   descomprimir los `/FlateDecode` con `zlib.inflateSync(..., { maxOutputLength })`. Topes
   candidatos: 16 MiB por stream y 32 MiB acumulados por PDF, a confirmar con fixtures reales.
   Exceso, stream sin cierre, longitud incoherente o inflate inválido → `CERTIFICATE_IMPORT_PDF_INVALID`.
2. **Cobertura de pdf-lib 1.17.1:** en el load solo `/Type /ObjStm` y `/Type /XRef` pasan por
   `ByteStream.fromPDFRawStream` (decode con pako). Esos streams con cualquier filtro distinto de
   `/FlateDecode` (LZW, ASCII85, RunLength, cadenas) se rechazan: no hay tope verificable para ellos.
   Los demás streams no se decodifican en el load; el pre-escaneo los acota igual de forma conservadora
   o documenta por qué se omiten.
3. **RED:** fixture sintética `/Type /ObjStm` + `/FlateDecode` ≤ 10 MiB cuyo inflate supera el tope:
   hoy pdf-lib la descomprime entera. **GREEN:** rechazo antes de pdf-lib, sin asignar más que el tope,
   proceso vivo. Además: ObjStm con LZW rechazado, PDFs reales 1–5 páginas aceptados, cifrado/truncado intactos.
4. Ambos llamadores (`confirm()` y el worker) pasan por el pre-escaneo; no hay una ruta pdf-lib sin él.
5. Comandos: `pnpm exec jest src/certificate-bulk-imports/certificate-import-pdf.spec.ts --runInBand`
   y las suites de `certificate-import-files.service.spec.ts`; ESLint `--no-fix` y `tsc --noEmit` acotados.

**Salida:** límite de asignación determinista y probado en local. Reemplaza al STOP de contención:
no hace falta Linux, cgroups, Docker ni Cloud Run para demostrarlo.

**Progreso 2026-10-07, corrección de revisión:** la primera implementación (pre-escaneo) no fue
aprobada. P1: el pre-escaneo no ve `/Obj#53tm`, un comentario `N G %x\\nobj`, ni una cabecera
`4\\n0\\nobj` después del trailer; pdf-lib asignó un buffer de 64 MiB (67108864) desde un archivo
de menos de 256 KiB. P2: el pre-escaneo se eliminó. Un `/Length` incorrecto es habitual en
escáneres y pdf-lib lo tolera; el pre-escaneo también rechazaba filtros que el load no decodifica
y se podía evadir. P3: las fixtures viven en `test/certificate-bulk-imports/`; `tsconfig.build.json`
volvió a su exclusión original. Pendiente de revisión independiente. No es `PASS_LOCAL_SLICE`.
No autoriza Task1b. No hubo build, commit ni despliegue.

El control es `DecodeStream.prototype.ensureBuffer` en pdf-lib 1.17.1, fijada sin caret.
`pnpm patch` modifica las copias `cjs/` y `es/` para que llamen un hook
(`sacdia.pdf-lib.decode-cap`) antes de `new Uint8Array`. Node, tsc y Jest resuelven `main` →
`cjs/index.js`. `es/` no lo instancia Node (imports sin extensión), pero es la entrada `module`
de un bundler; el parche cubre las dos. El tope por llamada usa `AsyncLocalStorage`: `PDFParser`
hace `await` entre objetos, así que dos `PDFDocument.load` se intercalan. Tope por stream 16 MiB,
acumulado 32 MiB, contando el `byteLength` del buffer (pdf-lib duplica hasta la potencia de dos).
Al pasar el tope se lanza antes de asignar y `assertCertificateImportPdf` responde
`CERTIFICATE_IMPORT_PDF_INVALID`, también si pdf-lib traga la excepción. Si el parche no está,
la función lanza `PDF decode cap is not installed` y no llama a `PDFDocument.load`.

RED, contra el pre-escaneo, `pnpm exec jest src/certificate-bulk-imports/certificate-import-pdf.spec.ts --runInBand --testTimeout=180000 -t "hex-escaped|comment|split header|double FlateDecode|escaped LZW|third ObjStm"`:
exit 1. Casos A, B y D: `maxBuffer` 67108864, no 16777216. Cadena `[/FlateDecode /FlateDecode]`:
`PDFDocument.load` no fue llamado (el pre-escaneo rechazó antes). LZW con nombre escapado, tras
corregir el codificador: `maxBuffer` 134217728. El tercer ObjStm dejó el total del espía en
33554944. Quitar el parche de `cjs/` y `es/` y repetir el caso hex: exit 1, `PDFDocument.load`
recibió 0 llamadas (fallo cerrado). El parche se restauró.

GREEN, desde `sacdia-backend/`:
`certificate-import-pdf.spec.ts` 33 passed, 2.082 s;
`certificate-import-files.service.spec.ts` 24 passed, 2.03 s;
`ocr/google-vision-certificate-ocr.provider.spec.ts` 39 passed, 2.169 s.
ESLint `--no-fix` sobre los archivos tocados: sin diagnósticos. `tsc --noEmit --pretty false -p tsconfig.build.json`: exit 0.
`git diff --check` en los archivos rastreados: sin hallazgos. En los archivos nuevos, `--check` no
imprimió errores de espacio.

`confirm()` y el worker siguen entrando por `assertCertificateImportPdf`. Los PDF de 1 y 5 páginas,
los cifrados, los truncados y los de más de 5 páginas conservan sus códigos. `parseXrefStream`
decodifica el xref después del load, dentro del mismo `AsyncLocalStorage`. Un stream sin filtro no
pasa por `ensureBuffer`; sus bytes ya están en el archivo, acotado a 10 MiB. Fuera de
`assertCertificateImportPdf` el hook no aplica el tope, para no cambiar otros usos de pdf-lib.

**Progreso 2026-10-07, pool de PDFRef:** el tope de descompresión no se reabre. P1: con
`/W [0 0 0]` y `/Index [0 N]`, pdf-lib recorre N entradas sin leer bytes y `PDFRef.of` retiene
cada ref en un pool de módulo que no desaloja. RED en proceso: PDF de 143 bytes, N=4e6,
`CERTIFICATE_IMPORT_PDF_INVALID`, y tras `global.gc()` el heap subió 438023952 bytes. El mismo
proceso con `/W [1500000000 0 0]` tardó 5341 ms y no dejó correr otra validación (plazo 2000 ms).
`assertPdfDecodeCapInstalled` volvió a leer `DecodeStream.js` en la segunda llamada.

GREEN: `load`, el xref final y el conteo de páginas van en un `worker_thread` que se termina al
cerrar cada validación. No se recicla: el pool no encoge. El padre copia el Buffer y transfiere
la copia; no importa pdf-lib. `resourceLimits` 256 MiB de old space y 64 MiB de young space. El
tope de decode sigue dentro del worker. Al vencer el plazo, `worker.terminate()` y
`CERTIFICATE_IMPORT_PDF_INVALID`. Si el worker muere por memoria, el padre sigue vivo y responde
INVALID. Sin el parche, el chequeo corre en el worker y el padre lanza
`Error: PDF decode cap is not installed` (comprobado; el parche quedó restaurado). El primer
éxito de `assertPdfDecodeCapInstalled` queda cacheado; un fallo no.

Heap del padre tras GC, mismo PDF de 143 bytes: delta −53624 bytes, INVALID, y el proceso del
probe termina (el worker no queda vivo). Overhead de un PDF de 1 página, cinco llamadas a
`assertCertificateImportPdf` con tsx: 173, 145, 140, 141, 150 ms (mediana 145). El mismo parse
en proceso: 4, 1, 0, 0, 0 ms. Un worker JS sin tsx que solo hace `PDFDocument.load` midió 62, 59,
59, 60, 58 ms. Producción usará el `.js` emitido; este corte no compiló.

Suites, desde `sacdia-backend/`: `certificate-import-pdf.spec.ts` 37 passed, 9.577 s;
`certificate-import-files.service.spec.ts` 24 passed, 2.496 s;
`ocr/google-vision-certificate-ocr.provider.spec.ts` 39 passed, 6.305 s.
ESLint `--no-fix` sin diagnósticos. `tsc --noEmit --pretty false -p tsconfig.build.json`: exit 0.
Pendiente de revisión independiente. No es `PASS_LOCAL_SLICE`. No autoriza Task1b. No hubo build,
commit ni despliegue.

**Progreso 2026-10-07, presupuesto Free:** el worker y la fuga del pool no se reabren. Render
Free es 512 MiB y 0,1 CPU, sin métricas. `render.yaml` dice starter y no se usó ni se modificó.
Supuesto escrito junto a las constantes: el padre Nest puede ocupar ~300 MiB
(`PDF_PARENT_RSS_ASSUMPTION_BYTES`). Una validación puede sumar como máximo 128 MiB de RSS
(`PDF_VALIDATION_RSS_BUDGET_BYTES`).

RED: seis validaciones a la vez no rechazaban la que no cabe; bajo el plazo único de 2 s desde
`new Worker` las seis terminaron en `CERTIFICATE_IMPORT_PDF_INVALID`. Avanzar 10 s un reloj
inyectado no cortaba el arranque: el PDF legítimo se aceptaba.

GREEN: semáforo de proceso, 1 worker activo y hasta 4 en espera
(`PDF_WORKER_MAX_ACTIVE`, `PDF_WORKER_MAX_WAITING`). La sexta llamada no crea worker y responde
`CERTIFICATE_IMPORT_OCR_UNAVAILABLE`: el PDF no se juzgó, así que `PDF_INVALID` pediría
reexportarlo y `FILE_LIMIT` significa que el lote ya tiene documento. `OCR_UNAVAILABLE` ya es el
código de "la vía automática no puede tomar esto ahora". La espera en cola vence a los 48 s
(`PDF_QUEUE_WAIT_MS` = 4 × (10 s + 2 s)) y usa el mismo código, sin worker. Arranque: 10 s desde
`new Worker` hasta `'online'` (`PDF_WORKER_STARTUP_DEADLINE_MS`). Parseo: 2 s desde `'online'`
(`PDF_PARSE_DEADLINE_MS`). Si vence el arranque o el parseo, `terminate()` y
`CERTIFICATE_IMPORT_PDF_INVALID`. La espera en cola no consume el plazo de parseo. Con
`__filename` terminado en `.js`, si falta el worker compilado no hay fallback a tsx: se loguea
`PDF validation worker bundle is missing` y se lanza ese error, sin bytes del PDF. El fallback a
tsx queda para tests y desarrollo.

Heap del worker: `maxOldGenerationSizeMb` 48 y `maxYoungGenerationSizeMb` 16. Los PDF legítimos
midieron ~20 MiB de heap y como máximo ~50 MiB de RSS extra. El tope de decode bajó de 16/32 MiB
a 1/2 MiB: ObjStm/XRef de 1 página, 5 páginas, un escaneo sintético de 9,2 MiB y los fixtures
QPDF quedan en 0–1024 bytes. `resourceLimits` no cubre ArrayBuffers.

RSS adicional del proceso, muestreo cada 5 ms, proceso frío (el padre no importa pdf-lib):

| Caso | RSS extra | Resultado | Tiempo |
| --- | ---: | --- | ---: |
| 1 página | 33,7 MiB | aceptado | 179 ms |
| 5 páginas | 34,5 MiB | aceptado | 161 ms |
| escaneo sintético 9,2 MiB | 50,3 MiB | aceptado | 169 ms |
| XRef `/W [0 0 0]` N=20e6 | 71,9 MiB | INVALID | 320 ms |
| 3 XRef N=20e6 concurrentes | 74,0 MiB | INVALID los tres | 903 ms |

La bomba de inflate (64 MiB lógicos), medida en el probe después de otros PDF: +4,3 MiB y
INVALID. Antes, un solo N=20e6 sumaba ~328 MiB y tres concurrentes ~761 MiB.

Overhead de un PDF de 1 página, cinco llamadas con tsx: 168, 177, 157, 174, 152 ms (mediana
168). El mismo parse en proceso: 5, 1, 1, 0, 0 ms. Producción usa el `.js` emitido; este corte
no compiló.

Limitaciones: el supuesto de 300 MiB del padre no está medido en Free. El factor ~10× por 0,1
CPU es una estimación, no una corrida en Render. 48 s de cola puede superar el tiempo de una
petición HTTP. El semáforo es por proceso: la API y el worker de OCR tienen cada uno el suyo.
Un ObjStm legítimo mayor a 1 MiB sería INVALID; lo medido cabe en 1 KiB.

Suites, desde `sacdia-backend/`: `certificate-import-pdf.spec.ts` 43 passed, 25.489 s;
`certificate-import-files.service.spec.ts` 24 passed, 15.646 s;
`ocr/google-vision-certificate-ocr.provider.spec.ts` 39 passed, 8.165 s.
ESLint `--no-fix` sin diagnósticos. `tsc --noEmit --pretty false -p tsconfig.build.json`: exit 0.
Pendiente de revisión independiente. No es `PASS_LOCAL_SLICE`. No autoriza Task1b. No hubo build,
commit ni despliegue.

**Progreso 2026-10-07, arranque, terminate y cola de confirm:** la contención de memoria no se
reabre. Quedó verificada aparte: XRef N=20e6 +70 MiB, tres concurrentes +29 MiB, heap retenido 0,
bombas de inflate rechazadas, 106 pruebas.

P2-a. RED: un reloj inyectado avanzó 5 s después de que el worker ya estaba en marcha y antes de
`{ ready: true }`. La promesa quedó resuelta. El plazo de parseo de 2 s corría desde `'online'`,
y `require('pdf-lib')` (44–81 ms en esta Mac, ~0,4–0,8 s a 0,1 CPU) consumía ese plazo. GREEN: el
worker envía `{ ready: true }` después de los imports y antes de parsear. `PDF_WORKER_STARTUP_DEADLINE_MS`
(10 s) cubre `new Worker` → ready. `PDF_PARSE_DEADLINE_MS` (2 s) empieza en ready. `'online'` no
arma el parseo. La misma prueba, con la carga retenida dentro de los 10 s, no resuelve al avanzar
5 s y después acepta el PDF de 1 página.

P2-b. RED: con `terminate()` que no termina, el segundo `assertCertificateImportPdf` entraba al
worker en cuanto el primero tenía resultado. GREEN: el lugar y `activeWorkers` se sueltan en
`'exit'` o cuando `terminate()` resuelve. `PDF_WORKER_EXIT_WAIT_MS` es 1 s. Si vence, se loguea
`PDF validation worker did not exit before the release deadline`, sin bytes del PDF, y se libera
igual. Mientras `terminate` no sale, `pdfValidationActiveWorkers()` sigue en 1 y
`pdfValidationWorkerPeak()` en 1. La respuesta al llamador sale con el mensaje de parseo y no
espera ese segundo.

P2-c, espera. `confirm()` pasa `PDF_CONFIRM_QUEUE_WAIT_MS` = 2 s. Arranque 10 s + parseo 2 s +
cola 2 s = 14 s, por debajo de `AppConstants.receiveTimeout` (15 s) aunque el arranque use su
tope. El proveedor OCR pasa `PDF_OCR_QUEUE_WAIT_MS` = 48 s, esto es 4 × (10 s + 2 s), y
`queueFullCode: CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. Cada llamador elige su espera. Una espera de
2 s no vence al llamador de 48 s.

P2-c, código: detenido. No hay un código de catálogo que signifique «reintentá más tarde».

Revisé `sacdia-backend/src/common/errors/error-codes.ts` y los locales
`sacdia-app/assets/translations/es.json`, `en.json`, `fr.json` y `pt-BR.json`. No aplica ninguno
de estos:

- `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`: Redis ausente al encolar, o ADC/autorización en el worker.
  La documentación dice que la evidencia ya confirmada permite captura manual. En `confirm()` el
  archivo no quedó sellado.
- `CERTIFICATE_IMPORT_STORAGE_UNAVAILABLE`: falta el bucket.
- `CERTIFICATE_IMPORT_FILE_LIMIT`: el lote ya tiene un documento.
- `CERTIFICATE_IMPORT_PDF_INVALID`: hay que reexportar el PDF.
- `CERTIFICATE_IMPORT_OCR_FAILED` y `CERTIFICATE_IMPORT_OCR_QUOTA`: la lectura ya se intentó, o
  Vision rechazó por cuota.
- `errors.too_many_attempts` y `profile.data_export.errors.rate_limit`, en los cuatro locales, son
  textos de login y de exportación. No son códigos de esta API.

Propuesta, sin crearla en el enum, los locales ni el `throw`:

- Código: `CERTIFICATE_IMPORT_PDF_BUSY`.
- HTTP 429. No 503: `http-exception.filter.ts` en producción sustituye `message` cuando
  `status >= 500`, y la app no vería el código. 429 conserva `message`.
- Mismo sobre legacy que los otros PDF: `message` igual al código, para el `switch` de
  `certificate_import_upload_view.dart`.
- Significado: la validación no tomó el turno; el archivo no quedó confirmado; reintentar el
  mismo `confirm`.
- El worker de OCR sigue respondiendo `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`.

Hasta que ese código exista, `confirm()` con la cola llena sigue lanzando el default
`CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. No lo reemplacé por un código inventado.

Suites, desde `sacdia-backend/`: `certificate-import-pdf.spec.ts` 48 passed, 14.079 s;
`certificate-import-files.service.spec.ts` 24 passed, 2.422 s;
`ocr/google-vision-certificate-ocr.provider.spec.ts` 39 passed, 3.197 s.
ESLint `--no-fix` sobre los archivos de este corte: sin diagnósticos.
`tsc --noEmit --pretty false -p tsconfig.build.json`: exit 2. Los cuatro errores están en
`certificate-bulk-imports-application.service.ts`, `certificate-bulk-imports.service.ts` e
`institutional-certificate-requests.service.ts` (`HistoricalAgeDb`). Este corte no los tocó; ya
tenían diff. Ningún error en los archivos de TaskR.
`git diff --check` en los archivos rastreados de este corte: sin hallazgos. El worker no
rastreado no tiene espacios finales ni marcadores de conflicto.
Pendiente de revisión independiente. No es `PASS_LOCAL_SLICE`. No autoriza Task1b. No hubo build,
commit ni despliegue. El código `CERTIFICATE_IMPORT_PDF_BUSY` no está creado.

**Progreso 2026-10-07, `CERTIFICATE_IMPORT_PDF_BUSY`:** el usuario aprobó el código. RED: cola
llena y espera vencida respondían HTTP 400. GREEN: `confirm()` pasa
`queueFullCode: CERTIFICATE_IMPORT_PDF_BUSY`. Cola llena o espera de 2 s vencida lanza
`HttpException` 429 con `message` igual al código, el mismo sobre legacy que los otros PDF.
No arranca worker, no sella y no borra evidencia. El llamador OCR sigue en
`CERTIFICATE_IMPORT_OCR_UNAVAILABLE` con HTTP 400. Traducciones en
`src/i18n/{es,en,fr,pt-BR}/errors.json` y en la app junto a `pdf_invalid`. La app reconoce el
código junto a los otros PDF y no reintenta el POST (`RetryInterceptor` sigue limitado a
métodos idempotentes). No hay spec HTTP del controller de `confirm`; el caso 429 está en
`certificate-import-files.service.spec.ts`, que llama `confirm()` directo. El e2e de jornada
no se tocó.

Suites, desde `sacdia-backend/`: `certificate-import-pdf.spec.ts` 51 passed, 17.613 s;
`certificate-import-files.service.spec.ts` 26 passed, 5.941 s;
`ocr/google-vision-certificate-ocr.provider.spec.ts` 39 passed, 3.882 s.
ESLint `--no-fix` sobre los archivos de este corte: sin diagnósticos.
`tsc --noEmit --pretty false -p tsconfig.build.json`: exit 0. En esta corrida no aparecieron
los errores `HistoricalAgeDb` vistos en el corte anterior; este corte no tocó esos archivos.
`git diff --check` en los archivos rastreados de este corte: sin hallazgos.
App: `flutter test` de las vistas y del pipeline de confirm pasó; `flutter analyze` de
`certificate_import_repository_impl.dart` y `certificate_import_upload_view.dart` no reportó
problemas. Los ocho JSON de traducción parsean.
Pendiente de revisión final. No es `PASS_LOCAL_SLICE`. No autoriza Task1b. No hubo build,
commit ni despliegue.

## Task3 — handler proxy y Vision, sin parseo PDF (slice3, reformulado 2026-10-07)

**Paths candidatos:** `sacdia-ocr-proxy/src/ocr/ocr.controller.ts`, `sacdia-ocr-proxy/src/ocr/ocr-orchestrator.ts`,
`sacdia-ocr-proxy/src/vision/vision-text-reader.ts`; `sacdia-ocr-proxy/test/ocr-handler.spec.ts`,
`sacdia-ocr-proxy/test/vision-text-reader.spec.ts`. Ya no existen `pdf-validator-worker.ts` ni
`pdf-isolation.spec.ts`; el proxy no depende de pdf-lib. Requiere Task1b.

1. **RED:** auth inválida, replay, conteo de páginas inválido, firma de magic bytes que no coincide
   con el MIME (`%PDF-`, JPEG, PNG, WebP; chequeo de cabecera, no parseo), cuota/store fallido: cero RPC.
2. FAIL → handler mínimo en orden bound/auth/hash → magic bytes → admisión con el conteo firmado →
   `CALLING` → RPC fuera del callback.
2b. **(Requisito de la revisión de Task1b.)** Hoy `verifyOcrRequest` solo devuelve `pageCount` y
   `admitOperation` recibe `operationId`, `issuedAt`, digest, MIME, longitud, nonce y timestamp por
   separado. El resultado verificado debe exponer **todos** los campos canónicos firmados, y
   `AdmitInput` debe construirse solo desde ese resultado (más `receivedAt`/`now`/`leaseMs`). RED:
   un handler que pasa un digest, MIME u `operationId` distinto del firmado no puede admitir.
3. **RED/GREEN SDK:** constructor con `apiEndpoint: 'us-vision.googleapis.com'`, `fallback: false`
   y topes gRPC de 12/16 MiB; cada `batchAnnotateImages`/`batchAnnotateFiles` recibe `CallOptions`
   `{ timeout: min(25_000, remanente), retry: { retryCodes: [] } }`. PDF con `pages: [1..N]`.
   ADC por service identity, sin fallback global ni GCS. Cliente lazy único, close en shutdown.
4. **RED/GREEN respuesta:** páginas faltantes/duplicadas/extra, error de archivo o página, orden 1..N,
   documento totalmente blanco falla, tope 16 MiB. `totalPages` informado ≠ N → `PAGE_COUNT_MISMATCH`,
   terminal post-`CALLING`, sin segunda llamada.
5. **RED/GREEN incertidumbre:** crash, deadline, red o fallo al persistir después de `CALLING`, y
   `COMPLETE` con respuesta perdida: el segundo intento va a manual sin Vision. Si `recordComplete`
   y `recordUnknown` devuelven `UNCERTAIN`, la llamada hecha sigue siendo la única. HTTP 504 no es cancelación.
6. **Plazo:** 35 s con `process.hrtime.bigint()` inyectable; cada espera, incluida la del ledger,
   acotada al remanente. Ledger sin resolver al vencer: la respuesta sale y el RPC no empieza; una
   resolución tardía no ejecuta el efecto.
7. **Privacidad:** el texto OCR completo va en `pages[].text` del JSON 200. Un marcador de prueba
   está ausente del error, logs, métricas y persistencia. Readiness no llama a Vision.
8. **Recursos:** perfil 1 vCPU/512 MiB/min 0/max 1/concurrencia 1. Sin parser PDF, la memoria queda
   dominada por cuerpo ≤ 10 MiB y JSON ≤ 16 MiB; medir cold start local como referencia, sin STOP.

**Salida:** servicio local no desplegado y tests de invariantes, no promesa exactly-once.

**Progreso 2026-10-07:** implementado en local. La revisión no lo aprueba todavía. No es
`PASS_LOCAL_SLICE`. No autoriza Task4, Task5 ni despliegue. `verifyOcrRequest` devuelve la
identidad canónica firmada y `admitOperation` arma `AdmitInput` solo desde ese resultado más
`receivedAt`/`now`/`leaseMs`. Los nombres `x-ocr-*` se comparan en minúsculas; un duplicado que
solo cambia mayúsculas, o un `x-ocr-*` desconocido en cualquier capitalización, es
`INVALID_CONTRACT`. La cuerda canónica no cambia. `POST /v1/ocr` verifica formato y HMAC del
digest declarado antes de leer; después lee con tope y `OCR_BODY_READ_TIMEOUT_MS` (10 s) y recién
entonces compara el digest real. `headersTimeout` es `OCR_HEADERS_TIMEOUT_MS` (10 s) y
`requestTimeout` es `OCR_REQUEST_TIMEOUT_MS` (35 s). Un corte de headers o de cuerpo responde el
sobre `DISCONNECTED`. Si `admit` devuelve `ALREADY_RESERVED` para la misma identidad, el handler
llama `recoverPlanned`: `RECOVERED` sigue con `confirmCalling` y el fence nuevo, y solo entonces
Vision; `NOT_RECOVERABLE` (CALLING, COMPLETE, UNKNOWN o lease vigente) es `CONFLICT` sin RPC;
`UNCERTAIN` no llama. El puerto no cambia la semántica Firestore ya aprobada. El server solo
escucha en `127.0.0.1`. El adaptador Vision es `@google-cloud/vision@6.1.1` (Apache-2.0,
`engines.node >= 22`), con fábrica inyectable, endpoint `us-vision.googleapis.com` y sin
`keyFilename`, credenciales ni API key. `PAGE_COUNT_MISMATCH` es HTTP 502. Todas las pruebas
simulan Vision. Cold start local no medido. Suite focal: 98 pruebas, 0 fallos.

**Historial:** la propuesta del 2026-10-06 (`PASS_PROPOSAL_WITH_STOP_GATE`, proceso hijo con pdf-lib
y presupuesto 256/160/416/96 MiB) queda **reemplazada** por esta versión. Sus secciones de SDK,
`UNKNOWN`, plazo y privacidad se conservan arriba. El STOP de contención pasa a TaskR.

## Task4 — adaptador Render y contexto estable (slice4)

**Decisión cerrada el 2026-10-07, opción (b):** el lease del ledger dura 60 s
(`DEFAULT_LEASE_MS`) y el reintento BullMQ llega a los 5 s. Si el reintento encuentra la
operación con lease vigente, el proxy responde `CONFLICT` y el archivo va a revisión manual
(`CERTIFICATE_IMPORT_OCR_FAILED`). No se reprograma después del lease y no se repite Vision.
La opción (a) (`Retry-After` y reprogramar el job) no se implementa. BullMQ conserva 2 intentos,
backoff fijo de 5 s y concurrencia 1. Los códigos terminales
(`FAILED`, `QUOTA`, `UNSUPPORTED_TYPE`, `FILE_TOO_LARGE` y los `PDF_*`) se lanzan como
`UnrecoverableError` para no gastar el segundo intento. `OCR_UNAVAILABLE` sigue siendo
reintentable.

**Punto de arranque de producción (Task5/rollout):** `listenOcr` solo escucha en `127.0.0.1`.
Cloud Run necesita un entrypoint separado en `0.0.0.0:$PORT` con configuración validada.

**Paths existentes afectados:**
`sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.provider.ts`,
`sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.queue.ts`,
`sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.processor.ts`,
`sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.service.ts`,
`sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.module.ts`,
`sacdia-backend/src/config/env.validation.ts` y sus specs indicadas arriba.
**Nuevo path candidato backend:**
`sacdia-backend/src/certificate-bulk-imports/ocr/cloud-run-certificate-ocr.provider.ts` y
`sacdia-backend/src/certificate-bulk-imports/ocr/cloud-run-certificate-ocr.provider.spec.ts`.

1. **RED:** job reintenta/reinicia/reencola mismo archivo: mismo opid/issuedAt; nueva evidencia
   no reutiliza viejo digest. Otro dueño es rechazado antes de R2/HTTP; nada de IDs humanos al proxy.
2. FAIL → incorporar solo contexto interno aprobado Task0; conservar public DTO/schema/ownership.
3. **RED/GREEN:** cliente binario HTTPS 40 s tentativo, no auth de Flutter, redirects ni omitir verificación TLS;
   env/kid separados, signing bytes reales y cap respuesta 16 MiB antes de parsear JSON.
4. **RED/GREEN:** mapping de errores a códigos existentes, no vendor/debugtext;429 manual sin
   cola para mañana; post-CALLING: segundo intento BullMQ sin RPC. Dos intentos/backoff 5 s/concurrencia 1 intactos.
   Solo un envelope JSON v1 válido decide el código: 429/5xx/504 de plataforma sin envelope
   (p. ej. Cloud Run sin instancia libre con max 1) → `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`, nunca `QUOTA`.
4b. **RED/GREEN conteo:** el adaptador firma `X-Ocr-Page-Count` con el conteo de
   `assertCertificateImportPdf` (tras TaskR) sobre el mismo Buffer sellado; imagen = 1. Sin conteo
   validado no hay request.
5. **RED/GREEN:** PDF/image seal exact Buffer, parser recibe texto completo antes de guardar 20k;
   resultado fallido no OCR_PROCESSED; revisión manual y approval del CampoLocal intactos.
6. DI/ConfigService/Joi: selector de modo validado, remoto incompleto fail-closed sin fallback
   ADC silencioso desde Render. Local Mac conserva modo directo aprobado. Secret names en ejemplo
   solo tras autorización de edición; nunca tocar `.env` real.
7. Repetir comandos backend existentes; agregar spec nueva a verify acotado. No afirmar noEmit global
   limpio: comparar diagnósticos propios con baseline actual y no corregir errores ajenos.

**Progreso 2026-10-07 (local, pendiente de revisión independiente).** No es `PASS_LOCAL_SLICE`.
No autoriza Task5 ni despliegue.

Variables (solo nombres, sin valores): `OCR_MODE`, `OCR_PROXY_URL`, `OCR_PROXY_ENV`,
`OCR_PROXY_KID`, `OCR_PROXY_SECRET`. `OCR_MODE=direct` (default) conserva ADC. `remote` exige
las cuatro restantes al arrancar; un secreto inválido no se copia al mensaje de Joi.

Verificación punta a punta, no commiteada, en `/tmp/ocr-task4-e2e.mts`:

```sh
OCR_FIRESTORE_EMULATOR_JAR=/tmp/sacdia-ocr-emulator/cloud-firestore-emulator-v1.22.0.jar \
env -u GOOGLE_APPLICATION_CREDENTIALS \
  sacdia-backend/node_modules/.bin/tsx \
  --tsconfig sacdia-backend/tsconfig.json \
  /tmp/ocr-task4-e2e.mts
```

Emulador `127.0.0.1:8099`, proyecto `demo-ocr-local`, el mismo JAR. `listenOcr` en
`127.0.0.1` con lector Vision simulado. Resultado: imagen y PDF de 5 pasan; el reintento con
lease vigente termina en `CERTIFICATE_IMPORT_OCR_FAILED` y Vision no recibe una segunda llamada.

Ajustes 2026-10-07, todavía pendientes de revisión. No es `PASS_LOCAL_SLICE` y no abre Task5.

- `OCR_PROXY_SECRET` en modo remote exige base64 estándar de al menos 32 bytes decodificados.
  El mensaje de error no incluye el secreto. `signOcrRequest` y el llavero rechazan menos de
  32 bytes. Los vectores de runtime usan un secreto de prueba de 32 bytes en ambas suites.
  `test-key-ocr-v1` (15 bytes) solo se comprueba con `createHmac`, fuera de la vía de runtime.
- Con `NODE_ENV=production`, `OCR_MODE` es obligatorio y `OCR_PROXY_URL` exige https.
  Desarrollo y test conservan el default `direct`. `http://127.0.0.1` solo fuera de producción.
- El POST al proxy tiene un deadline absoluto de 40 s, además del timeout de inactividad. El
  timer es inyectable. Una respuesta que gotea bytes se corta con `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`.

## Task5 — documentación, review y preparación (slice5)

1. Actualizar juntos comportamiento implementado y docs: `docs/features/carga-masiva-certificados.md`,
   `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md`,
   `docs/api/ARCHITECTURE-DECISIONS.md`, `docs/guides/google-vision-certificate-ocr.md`,
   `docs/steering/tech.md`; distinguir estado local/remoto y retirar recetas con claves para este modo.
2. Revisión independiente seguridad/contrato: replay durable, retry de transacción, fence, confirmación durable del commit,
   no texto caché/PII/logs, no fallback global, límites y manual tras fallos ambiguos.
3. Ejecutar tests/lint sobre archivos propios. Ejemplo existente backend sinfix:
   `pnpm exec eslint src/certificate-bulk-imports/ocr/cloud-run-certificate-ocr.provider.ts`
   y demás paths efectivamente cambiados. `pnpm exec tsc --noEmit --types node,jest` con comparación
   causal baseline; resultados históricos no prueban esta implementación futura.
4. `git diff --check` scoped; linkcheck/status de docs propios; HEAD/index/deltas y cambios concurrentes
   preservados. No stage/commit automático ni globalformatfix.
5. Gate antes de remote: confirmar proyecto producción/SA, Firestore DB existente/región inmutable,
   APIs y permisos mínimos, constraints de ubicación/requireInvokerIam/domainrestrictedsharing.
   Verificado en `sacdia-dev-489217` el 2026-10-07 (lectura): sin DRS, `requireInvokerIam` no
   impuesta, ubicaciones libres; invocación pública con `invoker-iam-disabled`. Repetir en producción.
   Solo reads si explícitamente autorizados; no resolver restricciones con grants públicos silenciosos.
6. Reportar configuración/infra necesaria y pedir aprobación específica antes de habilitar APIs, crear DB,
   política TTL, generar secretos Secret Manager/HMAC, IAM, build/containerpush o deploy.

## Validación remota y rollout — FUERA de la autorización local

Con autorización separada: preproducción primero, secretos server-only por entorno, Run/Firestore
us-east4 y VisionUS, perfil aprobado25/35/40s/1 CPU/512 MiB/min0/max1/concurrencia1.
Smoke live solo sintético sin PII y con volumen/costo autorizado: imagen/PDF1/PDF5, rechazoPDF6,
quota/replay/concurrencia y pérdidarespuesta sin RPC adicional. Confirmar logs sin contenido privado y manual.
Producción requiere proyecto identificado, precio Virginia verificado y aprobación independiente.
Render (2026-10-07): todos los servicios, incluido producción, están en plan Free (512 MB RAM,
0,1 CPU) hasta salir a producción; `render.yaml` declara `starter` y no refleja el dashboard.
TaskR se dimensiona para Free, el peor caso. Al elegir el plan pago, revisar los topes de memoria
y los plazos del worker PDF contra la RAM y CPU reales, y sincronizar `render.yaml`.
Alertas/capinstances no son tope de factura. No declarar residenciaVirginia de Vision ni de R2.
Rollback: apagar remoto y mantener manual/evidencia/ledger; nunca borrar UNKNOWN, resetear cuota,
usar configuración 0 o regenerar opid para forzar reread. No duplicar approvals de negocio.

## Criterio de cierre local

Contrato/layout gates resueltos, RED/GREEN guardado, suites focalizadas y review aprobados,
contención PDF de TaskR demostrada en Render o modo remoto bloqueado, docs sincronizadas con estado real,
sin nuevos diagnósticos propios noEmit. Nada de esto significa desplegado ni OCR live exitoso.
El siguiente trabajo recomendado es **solo el slice1**, después de autorizar implementación local
y resolver Task0; no el rollout remoto completo.
