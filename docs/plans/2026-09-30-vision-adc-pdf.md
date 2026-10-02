# Google Vision ADC y PDF de certificados — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Leer imágenes y todas las páginas de PDF de 1–5 páginas mediante Google Vision autenticado con ADC, sin sustituir la corrección del miembro ni la aprobación humana.

**Architecture:** Mantener la subida privada a R2, la confirmación/sellado y el worker BullMQ existentes. Una validación PDF compartida analiza bytes reales antes de sellar y nuevamente antes del OCR de documentos antiguos; el proveedor conserva su seam de dominio y usa el cliente oficial con transporte gRPC, deadline y sin retries internos. Las pantallas solo comunican restricciones y errores localizados.

**Tech Stack:** NestJS 11, TypeScript 6, Prisma 7, BullMQ, R2; Flutter/Riverpod/Dio; dependencias aprobadas: `@google-cloud/vision` 6.1.1 y `pdf-lib` 1.17.1.

---

## Estado y alcance

- Diseño funcional aprobado; usuario aprobó worktrees aislados.
- **APROBADO:** el usuario autorizó explícitamente `@google-cloud/vision` y `pdf-lib` (“si”); instaladas solo en backend aislado, con lockfile. No queda un gate de autorización de bibliotecas pendiente.
- Desarrollo/revisión aislados: `/Users/abner/.codex/worktrees/vision-adc-pdf/sacdia` (detached); backend/app separados en rama `codex/vision-adc-pdf`.
- Usuario autorizó después la integración selectiva al workspace principal `/Users/abner/Documents/development/sacdia`, preservando cambios abiertos. Los worktrees se conservan como respaldo; esto no autoriza despliegue.
- En la fase aislada no tocar checkouts principales. En la integración autorizada aplicar solo hunks aprobados, sin sustituir cambios de otros agentes. Nunca tocar `.env` reales, credenciales ni producción.
- **No builds, commits, migraciones, despliegues, pruebas de OCR facturables ni claves JSON.**
- No cambiar schema, permisos, endpoints ni lógica de aprobación/investidura.
- Un documento activo por lote; allow-list JPEG/PNG/WebP/PDF y máximo binario existente **10 MiB**.
- Fallar cerrado: PDF corrupto, cifrado, sin páginas o >5 páginas no se confirma/sella; PDF antiguo inválido no llega a Vision.
- OCR fallido/incompleto no registra `OCR_PROCESSED`; la corrección manual sigue disponible con evidencia confirmada válida.

## Fuentes y decisiones verificadas

- [Vision cuotas/límites](https://docs.cloud.google.com/vision/quotas): JSON máximo 10 MB; imagen máxima 20 MB; `files:annotate` máximo cinco páginas por solicitud. La política SACDIA limita el documento completo a cinco páginas, no es un límite absoluto de PDF de Google.
- [Cliente oficial Node](https://docs.cloud.google.com/nodejs/docs/reference/vision/latest) y [transportes del cliente](https://raw.githubusercontent.com/googleapis/google-cloud-node/main/packages/google-cloud-vision/src/v1/image_annotator_client.ts): usar `fallback: false` y bytes Buffer/protobuf. Esto evita el crecimiento base64 de la vía REST/JSON sin hacer públicos los objetos R2 ni copiar a GCS.
- [InputConfig](https://docs.cloud.google.com/vision/docs/reference/rest/v1/InputConfig): PDF inline con MIME `application/pdf`; petición explícita de páginas `1..pageCount`.
- [pdf-lib page count](https://pdf-lib.js.org/docs/api/classes/pdfdocument#getpagecount) y [load options](https://pdf-lib.js.org/docs/api/interfaces/loadoptions): analizar estructura real; no contar `/Page` por regex.
- [pdf-lib cifrado](https://github.com/Hopding/pdf-lib#encryption-handling): rechazo por defecto de documentos cifrados; nunca activar `ignoreEncryption`.
- Tradeoff: SDK agrega dependencias y gRPC; evita implementar renovación OAuth/manual y no obliga a reducir artificialmente el límite binario por base64. `pdfkit` existente genera PDFs, no sirve como parser de documentos recibidos.
- ADC local ya configurado para `sacdia-dev-489217`. Cuenta preprod creada: `sacdia-vision-preprod@sacdia-dev-489217.iam.gserviceaccount.com`, rol `roles/serviceusage.serviceUsageConsumer`. Sin clave creada ni cambios en Render.

## Contrato implementado para separar ownership

Archivo nuevo `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-import-pdf.ts`:

```ts
export const CERTIFICATE_IMPORT_MAX_PDF_PAGES = 5;
export async function assertCertificateImportPdf(bytes: Buffer): Promise<number>;
```

- Precondición: lectura acotada al máximo existente; helper valida también bytes positivos, límite y magic `%PDF`.
- Analizar con `PDFDocument.load(bytes, { ignoreEncryption: false, throwOnInvalidObject: true, updateMetadata: false })`.
- Conteo entero, finito y positivo; devolverlo solo si <=5.
- HTTP 400 estable: `CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES`, `CERTIFICATE_IMPORT_PDF_INVALID`, `CERTIFICATE_IMPORT_PDF_ENCRYPTED`. No incluir mensajes internos del parser.
- Mantener códigos existentes de tamaño, MIME, archivo ausente, storage y OCR; añadir catálogo/i18n de nuevos errores si corresponde al pipeline efectivo.
- La UI muestra máximo cinco páginas y traduce estos tres errores. No duplicar el parser en Flutter.
- El proveedor verifica que el conjunto de `context.pageNumber` de resultados PDF sea exactamente `1..pageCount`; cada página sin error. Páginas vacías válidas pueden existir; ausencia total de texto usable sigue siendo OCR_FAILED.

### Task 1: Autorizar e instalar dependencias aisladas

**Files:** `/Users/abner/Documents/development/sacdia/sacdia-backend/package.json`, `/Users/abner/Documents/development/sacdia/sacdia-backend/pnpm-lock.yaml`.

1. Confirmar autorización explícita de bibliotecas antes de agregar.
2. Resolver versiones mantenidas compatibles con Node24; declarar ambas directas y registrar lockfile en este worktree, con scripts deshabilitados.
3. Verificar tipos/interfaces efectivas del SDK instalado y límites gRPC de mensajes; fijar límite de envío para soportar 10 MiB más envelope sin tamaño ilimitado.
4. Revisar audit high/critical según script existente; no arreglar vulnerabilidades ajenas ni hacer upgrades amplios.
5. Registrar decisión y cualquier incompatibilidad antes de seguir. No commits.

### Task 2: Validador PDF compartido (RED → GREEN)

**Create:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-import-pdf.ts`, `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-import-pdf.spec.ts`.

1. Escribir tests reales: PDF1, PDF5, PDF6, PDF0, bytes vacíos/no PDF, truncado, objetos inválidos y PDF realmente cifrado. Fixtures generadas con pdf-lib; cifrado usando pdfkit existente, nunca mockear el parser.
2. Ejecutar `pnpm exec jest src/certificate-bulk-imports/certificate-import-pdf.spec.ts --runInBand` desde backend y observar RED por comportamiento inexistente.
3. Implementar helper mínimo y mapear cifrado antes del catch genérico. Conteo basado en árbol de páginas, no número de matches de texto.
4. Repetir hasta GREEN. Cubrir los límites de bytes y prohibición de aceptar cifrado/0/>5.
5. Revisar exposición de parser a archivos maliciosos: límite de bytes no es límite de CPU ni de descompresión. Registrar riesgo y no afirmar sandboxing del parser inexistente.

### Task 3: Rechazar PDF inválido antes de confirmar/sellar (RED → GREEN)

**Modify:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-import-files.service.ts`.
**Test:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-import-files.service.spec.ts`.

1. Escribir tests de confirm PDF1/5 y rechazos6/cifrado/corrupto: en rechazo no `copyObject`, no update CONFIRMED ni borrar staging.
2. Ejecutar suite y observar RED contra comportamiento actual (solo magic bytes).
3. Tras validación HEAD/magic existente y antes de copy/seal, descargar PDF mediante `getObject` con `maxBytes: CERTIFICATE_IMPORT_MAX_BYTES`; validar longitud y contenido reales, ejecutar helper compartido.
4. Preservar confirmación idempotente existente y ownership; documentos antiguos ya CONFIRMED quedan protegidos por Task4 antes del OCR.
5. Ejecutar suite hasta GREEN y regresión imágenes/tamaño/MIME/storage/ausente. No schema nuevo.

### Task 4: Proveedor Vision ADC + PDF completo (RED → GREEN)

**Modify:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/ocr/google-vision-certificate-ocr.provider.ts`.
**Test:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/ocr/google-vision-certificate-ocr.provider.spec.ts`, `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.processor.spec.ts`.

1. Mockear solo cliente externo/factory; tests garantizan que ausencia de GOOGLE_VISION_API_KEY no bloquea ADC. Verificar Nest DI real no intenta inyectar una función fetch.
2. RED: image Buffer + DOCUMENT_TEXT_DETECTION/es; PDF1/5 requests con inputConfig.content Buffer, application/pdf y páginas explícitas. PDF6/cifrado/corrupto nunca llama SDK.
3. Implementar cliente lazy/reutilizado con `fallback:false`, sin apiKey; inyectar seam por provider token o propiedad/factory compatible con patrones Nest, no parámetro fetch sin token.
4. CallOptions con timeout acotado (25s actual) y retryCodes vacíos; BullMQ sigue único responsable de dos intentos. Probar opciones efectivas; no usar Promise.race como cancelación ficticia.
5. Tests resultados fuera de orden, páginas faltantes/duplicadas/extra, error por archivo/página, respuesta vacía, quota8/429, auth7/16/ADC faltante, timeout4 y fallo externo. Nunca aceptar éxito parcial.
6. Ordenar texto por página, concatenarlo y mantener parser/limit de texto guardado20k existentes; no truncar páginas enviadas. Cualquier fallo debe dejar worker sin OCR_PROCESSED.
7. GREEN + pruebas processor/workflow relevantes; no llamadas reales a Vision.

### Task 5: Configuración y mensajes visibles (RED → GREEN)

**Backend files:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/config/env.validation.ts`, `/Users/abner/Documents/development/sacdia/sacdia-backend/.env.example`, `/Users/abner/Documents/development/sacdia/sacdia-backend/src/common/errors/error-codes.ts`, `/Users/abner/Documents/development/sacdia/sacdia-backend/src/i18n/{en,es,fr,pt-BR}/errors.json`, pruebas de validación correspondientes.
**App files:** `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/presentation/views/certificate_import_upload_view.dart`, `/Users/abner/Documents/development/sacdia/sacdia-app/assets/translations/{en,es,fr,pt-BR}.json`.
**App tests:** `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/certificate_import/presentation/views/certificate_import_flow_views_test.dart`, `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/certificate_import/data/datasources/certificate_import_upload_pipeline_test.dart`.

1. Resolver cómo pasan los códigos a la UI usando el pipeline real; escribir RED de los tres errores PDF y hint máximo5 páginas.
2. Config validada opcional ADC: GOOGLE_APPLICATION_CREDENTIALS ruta archivo; GOOGLE_CLOUD_PROJECT proyecto; cuota según ADC/GOOGLE_CLOUD_QUOTA_PROJECT si SDK lo soporta. Nunca validar leyendo/imprimiendo JSON de claves.
3. Documentar que GOOGLE_VISION_API_KEY deja de autenticar este proveedor; no hacer obligatorio tener ADC al arrancar si OCR deshabilitado/sin Redis.
4. UI localizada conserva signed PUT sin Authorization, navegación/revisión manual cuando OCR falla y estados de selección/carga. No rediseño del admin ni dependencia PDF móvil.
5. Ejecutar tests app focalizados hasta GREEN; analyzer solo superficies tocadas, sin flutter build.

### Task 6: Docs, regresión y entrega

**Modify:** `/Users/abner/Documents/development/sacdia/docs/features/carga-masiva-certificados.md`, `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `/Users/abner/Documents/development/sacdia/docs/api/FRONTEND-INTEGRATION-GUIDE.md`, `/Users/abner/Documents/development/sacdia/docs/steering/tech.md` (decisión proveedor ADC).
**Create:** `/Users/abner/Documents/development/sacdia/docs/guides/google-vision-certificate-ocr.md`.

1. Actualizar restricciones reales, códigos confirm/OCR, identidad ADC, estados asynchronous worker y alcance humano de revisión. No afirmar implementación desplegada.
2. Runbook Mac: ADC gcloud login + set-quota-project; backend usa ADC, no copiar credenciales personales a servidor. Checklist Redis/R2/Vision/billing.
3. Runbook Render: Secret File de cuenta dedicada, GOOGLE_APPLICATION_CREDENTIALS=/etc/secrets/<filename>, proyecto por ambiente; claves tratadas como secret, rotación y privilegio mínimo. SA producción separada. Generar/subir claves y redeploy fuera de esta implementación, sujetos a autorización.
4. Baseline/regresión backend: `pnpm exec jest src/certificate-bulk-imports --runInBand`.
5. Baseline/regresión app: `flutter test test/features/certificate_import --no-pub`.
6. Lint sin fix destructivo: ESLint solo archivos TS tocados; Prettier check; Flutter analyze rutas tocadas; git diff --check por repo.
7. Revisar diffs y contratos; guardar descubrimientos/decisiones en Engram y resumen final. Reportar limitaciones de verificación sin fingir OCR live probado.

## Baseline de preparación

- Dependencias existentes instaladas en worktree con `pnpm install --offline --frozen-lockfile --ignore-scripts` y `flutter pub get --offline`; lockfiles/repos permanecen limpios.
- `pnpm exec prisma generate` completó cliente7.9.1 local; sin conexión DB/migraciones/build.
- Backend: `pnpm exec jest src/certificate-bulk-imports --runInBand` → **17 suites / 133 tests passed**, 113.618 s, salida 0.
- App: `flutter test test/features/certificate_import --no-pub` → **16 tests passed**, 2 min 16 s, salida 0.
- Aviso de test UI existente: Haze usa bandas de blur porque este host de test no dispone del filtro shader/Impeller; no falló ningún test.
- No smoke real de Vision, R2 ni Redis; todas las pruebas focalizadas anteriores son locales.

## Handoff y riesgos

- Ownership separable: helper/confirm + tests; proveedor/config + tests; app/locale + tests; docs/revisión por coordinador. Evitar escritores concurrentes en package/lock/error-codes.
- Git worktrees contienen development comprometido, no cambios sucios del checkout principal; no integrar de vuelta de forma automática ni sobreescribirlos.
- No validar límite Google gRPC con OCR facturable dentro de unit tests; documentar smoke preprod pendiente.
- Bibliotecas agregan superficie de dependencias; aprobación por nombre y audit antes de implementación.
- Parser estructural no garantiza que Google pueda renderizar cada página; error de página debe fallar todo el OCR.


## Estado de ejecución (2026-10-01)

- [x] Task 1: dependencias autorizadas/resueltas e instaladas en worktree; SDK 6.1.1, pdf-lib 1.17.1. gRPC pin 1.14.5; En ese baseline persistían hallazgos high ajenos (Joi, brace-expansion, engine.io); corregidos posteriormente con autorización expresa, según estado de parches abajo.
- [x] Task 2: helper PDF compartido con parser real; PDF1/5 aceptados, PDF0/6/cifrado/corrupto/truncado rechazados. Cierre/xref mínimo validado, no norma ISO completa ni CPU sandbox.
- [x] Task 3: confirmación PDF valida y sella el mismo Buffer con clave exclusiva por intento; relectura DB evita borrar evidencia cuando el commit es ambiguo. Posibles huérfanos requieren operación futura, no limpieza indiscriminada.
- [x] Task 4: proveedor oficial ADC lazy singleton, gRPC Buffer, deadline25s/sin retry SDK, resultados PDF completos; backend revisado y **244 tests GREEN** según verificación de la superficie backend.
- [x] Task 5 (backend): variables ADC opcionales validadas y mensajes PDF catalogados; API key ya no autentica.
- [x] Task 5 (app): hint PDF≤5/10MiB y mensajes accionables en es/en/fr/pt-BR; whitelist exacta en pipeline legacy message/campo code, mantiene core Failure.code HTTP int y fallback amigable. Sin parser móvil, sin nuevas dependencias ni cambio signed PUT/navegación manual. RED inicial: 5 widgets y 6 HTTP respuestas; regresión final: `flutter test test/features/certificate_import --no-pub` → **37 tests GREEN**; `flutter analyze --no-pub lib/features/certificate_import test/features/certificate_import` → **sin issues**.
- [x] Task 6 (documentación): feature, API, integración, stack y runbook Mac/Render sincronizados con código efectivo; no afirmar despliegue.
- [x] Task 6 (revisión/verificación): revisión independiente de especificación app/docs y revisión final de calidad/consolidación completadas, **sin bloqueadores**. Regresión fresca consolidada: backend **244 tests GREEN**, app **37 tests GREEN**, analyzer focalizado **sin issues** y diff checks **limpios**.
- [x] Integración al checkout principal autorizada por el usuario y aplicada por hunks selectivos. Cada hunk conserva un comprobante de inversa byte-idéntica al snapshot previo; traducciones ajenas preservadas por clave. Sin commit, PR, staging ni despliegue. Verificación primaria registrada abajo.
- [ ] Fuera del alcance autorizado: claves JSON/Secret File Render, redeploy y smoke Vision facturable (imagen/PDF1/PDF5/transporte cerca de10MiB). ADC local y cuenta preprod preparados no equivalen a runtime remoto comprobado.

Typecheck backend `tsc --noEmit`: 117 diagnósticos, idénticos a HEAD, ninguno nuevo; no es un build ni un repo global GREEN. No arreglar baseline ajena dentro de este cambio.


## Integración autorizada al workspace principal (2026-10-01)

- Destino: `/Users/abner/Documents/development/sacdia`; se aplicaron 37 paths aprobados, sin commits, staging, cambio de rama ni modificación del worktree fuente.
- Snapshot de seguridad privado: `/private/tmp/sacdia-vision-integration-20261001-085029`. Los 12 archivos compartidos conservan las modificaciones anteriores: invertir únicamente el patch aprobado produce exactamente el contenido inicial. Las ocho traducciones preservan todas las claves ajenas.
- Se conservaron los 137 registros previos de `git status`. 82 archivos dirty no pertenecientes al cambio mantienen su hash; `institutional-certificate-requests.service.spec.ts` recibió una modificación concurrente ajena, registrada sin restaurarla ni atribuirla a esta integración.
- Instalación exacta `pnpm install --frozen-lockfile --ignore-scripts` completada tras caché offline incompleta; package/lock idénticos a los aprobados. `pnpm exec prisma generate` regeneró solo el cliente local usando el schema vigente, sin migración ni conexión DB.
- Baseline primaria: `pnpm exec jest certificate-bulk-imports certificate-import env.validation.spec --runInBand` → **19 suites /179 tests**; `flutter test test/features/certificate_import --no-pub --reporter expanded` → **16 tests**; analyzer focalizado limpio.
- Regresión primaria: mismo comando Jest → **20 suites /261 tests**; misma superficie Flutter → **37 tests**, analyzer limpio y comprobación de formato de los cuatro Dart integrados sin cambios. Total primario: **298 pruebas**. Las cifras incluyen los cambios previos de otros trabajos, no sustituyen la cifra aislada.
- ESLint de TS integrados: limpio salvo un formato previo en la spec compartida de bulk imports; reproducido sobre el snapshot anterior (línea541→554), no corregido para respetar ownership. Los demás archivos integrados pasan ESLint. Diff checks y enlaces locales de documentación válidos; contexto Graft refrescado, no build runtime.
- La consulta inicial `pnpm audit --json` fue rechazada por auto-review debido al envío no autorizado del árbol de dependencias. No se eludió: el usuario autorizó después expresamente nombres/versiones y se ejecutó una nueva auditoría primaria. Luego autorizó los parches acotados detallados abajo.
- Typecheck causal con `types: [node, jest]`, `noEmit` e incremental deshabilitado: snapshot de fuentes previas y fuentes integradas evaluados con las mismas dependencias/client generado actuales → **123 diagnósticos antes /123 después, delta0**. Es comparación CompilerHost de fuentes, no recreación histórica completa del ambiente. El comando CLI actual `pnpm exec tsc --noEmit --incremental false --pretty false --types node,jest` confirma123 diagnósticos existentes y salida2; el primer CLI capturado antes sin `--types` contenía ruido masivo de globals Jest ausentes. No afirmar typecheck global limpio.
- La autorización del audit online ya fue concedida; siguen pendientes configuración Render/Secret File, despliegue y smoke facturable. No hay afirmación de producción lista.


## Parches de seguridad acotados autorizados (2026-10-01)

- Usuario autorizó actualización focalizada: **Joi18.2.3→18.2.6**, **brace-expansion1.1.18→1.1.21 y5.0.9→5.0.12**, **engine.io6.6.9→6.6.10**. No se tocaron gRPC1.14.5, Vision/pdf-lib, Prisma ni la excepción deepmerge-ts.
- Joi fijado exactamente18.2.6 para no resolver18.2.9 fuera del target aprobado. Overrides brace@1 conservan major1; brace@2 y@5 fijan5.0.12: el selector@2 ya resolvía5.0.9 en el lock previo, por lo que no introduce un nuevo salto de major. Delta semántico lock: solo cuatro versiones reemplazadas, referencias de minimatch/socket.io y overrides autorizados; registros de paquetes ajenos iguales. Engine.io6.6.10 elimina su dependencia base64id, sin actualización de otros paquetes.
- Instalación `pnpm install --frozen-lockfile --ignore-scripts --prefer-offline`; cliente Prisma generado existente conservado, sin regeneración/DB/build.
- Verificación fresca: mismo Jest focalizado **20 suites/261 pruebas** antes y después; `node --test scripts/audit-security.test.js` **5 pruebas** pasan. App no modificada;37 pruebas app pertenecen a la verificación de integración anterior, no se repitieron en este parche.
- `pnpm audit --json` autorizado después del parche: **0 críticas, 1 alta, 10 moderadas y2 bajas**, salida1 por avisos restantes. Replay offline del JSON mediante funciones efectivas de `scripts/audit-security.js`: **0 bloqueantes, 1 alta aceptada (deepmerge-ts hasta2026-11-23), 0 expiradas**, política salida equivalente0. NO significa repositorio libre de vulnerabilidades.
- Evidencia: `/private/tmp/sacdia-security-patches-20261001-120027`; snapshots/delta semántico, hashes ajenos y logs permiten revisar solo el cambio autorizado. Cambios concurrentes ajenos se registran sin restaurarlos. Sin commits, staging, despliegues ni smoke facturable.
