# Plan de implementación local — OCR keyless

**Estado documental:** ACTIVE
**Fecha:** 2026-10-02
**Diseño aceptado; implementación pendiente; no ejecutado ni desplegado.**

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

## Estrategia de entrega y riesgo de revisión

Estimación orientativa futura: 900–1600 líneas entre runtime y pruebas; riesgo **alto >400 líneas**.
Recomendados slices autónomos encadenados: (1) contrato/HMAC, (2) ledger/admisión,
(3) handler/Vision, (4) adaptador Render, (5) docs/verificación. Antes de aplicar, el coordinador
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

Proxy: tras aprobar Task0, usar su runner confirmado. Candidato Jest, desde su package:
`pnpm exec jest test/ocr-contract.spec.ts --runInBand`; los archivos/runner siguientes son propuestos,
no existen todavía ni se presentan como comandos disponibles hoy.

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

## Task3 — handler proxy, PDF aislado y Vision (slice3)

**Paths candidatos:** `sacdia-ocr-proxy/src/ocr/ocr.controller.ts`, `sacdia-ocr-proxy/src/ocr/ocr-orchestrator.ts`,
`sacdia-ocr-proxy/src/vision/vision-text-reader.ts`, `sacdia-ocr-proxy/src/pdf/pdf-validator-worker.ts`;
`sacdia-ocr-proxy/test/ocr-handler.spec.ts`, `sacdia-ocr-proxy/test/vision-text-reader.spec.ts`, `sacdia-ocr-proxy/test/pdf-isolation.spec.ts`.

1. **RED:** auth inválida, replay, cuerpos inválidos/cifrados/corruptos/truncados/>5páginas,
   cuota/store fallido: cero RPC; usar PDFs reales y mock SDK, no mock parser.
2. FAIL → handler minimal en orden bound/auth/hash→PDF→admisión→CALLING→RPC fuera callback.
3. **RED/GREEN:** una llamada SDK 25 s/retryCodes[], ADC serviceidentity, endpoint US obligatorio,
   ninguna ruta global fallback ni GCS. Cliente lazy único/close en shutdown como baseline.
4. **RED/GREEN:** páginas faltantes/duplicadas/extra/totalPages discordante/error de archivo o página,
   orden1..N, una página blanca admisible pero documento totalmente blanco falla;cap de 16 MiB.
5. **RED/GREEN:** crash/deadline/red/persistfailure después de CALLING y COMPLETE con respuesta perdida:
   segundo intento va manual sin Vision. HTTP504 no se interpreta como cancelación.
6. Aislamiento PDF: proceso/worker con deadline, límites de memoria y salida; probar fixtures
   de expansión/carga, terminación y liberación. Perfilar 512MiB/coldstart/concurrencia1 offline.
   Si no se demuestra seguridad/viabilidad, STOP antes de habilitar; no subir recursos silenciosamente.
7. Validar envelope allowlist y métricas sin contenido privado; readiness no llama Vision facturable.

**Salida:** servicio local no desplegado y tests probando invariantes, no promesa exactly-once.

## Task4 — adaptador Render y contexto estable (slice4)

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
5. **RED/GREEN:** PDF/image seal exact Buffer, parser recibe texto completo antes de guardar 20k;
   resultado fallido no OCR_PROCESSED; revisión manual y approval del CampoLocal intactos.
6. DI/ConfigService/Joi: selector de modo validado, remoto incompleto fail-closed sin fallback
   ADC silencioso desde Render. Local Mac conserva modo directo aprobado. Secret names en ejemplo
   solo tras autorización de edición; nunca tocar `.env` real.
7. Repetir comandos backend existentes; agregar spec nueva a verify acotado. No afirmar noEmit global
   limpio: comparar diagnósticos propios con baseline actual y no corregir errores ajenos.

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
   Solo reads si explícitamente autorizados; no resolver restricciones con grants públicos silenciosos.
6. Reportar configuración/infra necesaria y pedir aprobación específica antes de habilitar APIs, crear DB,
   política TTL, generar secretos Secret Manager/HMAC, IAM, build/containerpush o deploy.

## Validación remota y rollout — FUERA de la autorización local

Con autorización separada: preproducción primero, secretos server-only por entorno, Run/Firestore
us-east4 y VisionUS, perfil aprobado25/35/40s/1 CPU/512 MiB/min0/max1/concurrencia1.
Smoke live solo sintético sin PII y con volumen/costo autorizado: imagen/PDF1/PDF5, rechazoPDF6,
quota/replay/concurrencia y pérdidarespuesta sin RPC adicional. Confirmar logs sin contenido privado y manual.
Producción requiere proyecto identificado, precio Virginia verificado y aprobación independiente.
Alertas/capinstances no son tope de factura. No declarar residenciaVirginia de Vision ni de R2.
Rollback: apagar remoto y mantener manual/evidencia/ledger; nunca borrar UNKNOWN, resetear cuota,
usar configuración 0 o regenerar opid para forzar reread. No duplicar approvals de negocio.

## Criterio de cierre local

Contrato/layout gates resueltos, RED/GREEN guardado, suites focalizadas y review aprobados,
validación de recursos PDF demostrada o modo remoto bloqueado, docs sincronizadas con estado real,
sin nuevos diagnósticos propios noEmit. Nada de esto significa desplegado ni OCR live exitoso.
El siguiente trabajo recomendado es **solo el slice1**, después de autorizar implementación local
y resolver Task0; no el rollout remoto completo.
