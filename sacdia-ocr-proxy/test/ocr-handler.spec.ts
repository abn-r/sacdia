import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import net from 'node:net';
import { describe, it } from 'node:test';
import type { OcrKeyRing } from '../src/auth/ocr-signature.ts';
import { listenOcr } from '../src/http/ocr-server.ts';
import type {
  AdmitInput,
  AdmitResult,
  ConfirmCallingInput,
  ConfirmCallingResult,
  OcrLedger,
  RecordInput,
  RecordResult,
  RecoverResult,
} from '../src/ledger/ocr-ledger.port.ts';
import {
  OCR_BODY_MAX_BYTES,
  OCR_RESPONSE_MAX_BYTES,
} from '../src/ocr/ocr-contract.ts';
import {
  handleOcrRequest,
  type OcrRuntime,
} from '../src/ocr/ocr-orchestrator.ts';
import type {
  VisionReadInput,
  VisionReadResult,
  VisionTextReader,
} from '../src/vision/vision-text-reader.ts';
import { nonceFor, operationId } from './support/ledger-sample.ts';
import {
  OCR_MARKER,
  OCR_SECRET,
  SIGN_NOW,
  jpegBytes,
  pdfBytes,
  pngBytes,
  signOcrBytes,
  webpBytes,
  type SignedOcr,
} from './support/signed-ocr.ts';

describe('handler OCR', () => {
  it('devuelve el texto firmado y admite solo la identidad firmada', async () => {
    const started = Date.now();
    const signed = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
    });
    const harness = harnessFor({
      read: okPages([OCR_MARKER]),
    });
    const result = await post(harness.runtime, signed);
    assert.equal(result.status, 200);
    const body = JSON.parse(result.body.toString('utf8')) as {
      version: string;
      operationId: string;
      pageCount: number;
      pages: Array<{ pageNumber: number; text: string }>;
    };
    assert.equal(body.version, 'v1');
    assert.equal(body.operationId, signed.operationId);
    assert.equal(body.pageCount, 1);
    assert.equal(body.pages[0]?.text, OCR_MARKER);
    assert.equal(harness.reader.calls.length, 1);
    assert.equal(harness.ledger.admits[0]?.digest, signed.digest);
    assert.equal(harness.ledger.admits[0]?.mime, 'image/jpeg');
    assert.equal(harness.ledger.admits[0]?.operationId, signed.operationId);
    assert.equal(harness.ledger.admits[0]?.byteLength, signed.body.length);
    assert.equal(harness.ledger.admits[0]?.nonce, signed.nonce);
    assert.equal(harness.ledger.admits[0]?.pageCount, 1);
    assert.equal(JSON.stringify(harness.logs).includes(OCR_MARKER), false);
    assert.equal(JSON.stringify(harness.metrics).includes(OCR_MARKER), false);
    assert.equal(Date.now() - started < 1_000, true);
  });

  it('pide el PDF con el conteo firmado, sin interpretarlo', async () => {
    const signed = signOcrBytes({
      body: pdfBytes(),
      mime: 'application/pdf',
      pageCount: 5,
      nonce: nonceFor(2),
    });
    const harness = harnessFor({
      sleep: immediateSleep,
      read: okPages(['a', 'b', 'c', 'd', 'e'], 5),
    });
    const result = await post(harness.runtime, signed);
    assert.equal(result.status, 200);
    assert.equal(harness.reader.calls[0]?.pageCount, 5);
    assert.equal(harness.reader.calls[0]?.mime, 'application/pdf');
    assert.equal(harness.ledger.admits[0]?.pageCount, 5);
    const body = JSON.parse(result.body.toString('utf8')) as {
      pageCount: number;
      pages: Array<{ pageNumber: number }>;
    };
    assert.equal(body.pageCount, 5);
    assert.deepEqual(
      body.pages.map((page) => page.pageNumber),
      [1, 2, 3, 4, 5],
    );
  });

  it('no llama a Vision si la firma, el replay, la cuota o el ledger fallan', async () => {
    const signed = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      nonce: nonceFor(3),
    });
    const cases: Array<{
      name: string;
      headers?: SignedOcr['headers'];
      admit?: AdmitResult | (() => Promise<AdmitResult>);
      confirm?: ConfirmCallingResult;
      status: number;
      code: string;
    }> = [
      {
        name: 'firma',
        headers: signed.headers.map((header, index) =>
          index === signed.headers.length - 1
            ? [header[0], 'ab'.repeat(32)]
            : header,
        ) as SignedOcr['headers'],
        status: 401,
        code: 'UNAUTHORIZED',
      },
      {
        name: 'replay',
        admit: { status: 'REPLAY' },
        status: 401,
        code: 'UNAUTHORIZED',
      },
      {
        name: 'cuota',
        admit: { status: 'QUOTA' },
        status: 429,
        code: 'QUOTA',
      },
      {
        name: 'ledger caído',
        admit: { status: 'UNAVAILABLE' },
        status: 503,
        code: 'UNAVAILABLE',
      },
      {
        name: 'ledger lanza',
        admit: () => Promise.reject(new Error(OCR_MARKER)),
        status: 503,
        code: 'UNAVAILABLE',
      },
      {
        name: 'CALLING no confirmado',
        confirm: { status: 'UNCERTAIN' },
        status: 504,
        code: 'UNCERTAIN',
      },
      {
        name: 'fence perdido',
        confirm: { status: 'LOST_FENCE' },
        status: 409,
        code: 'CONFLICT',
      },
    ];
    for (const item of cases) {
      const harness = harnessFor({
        sleep: immediateSleep,
        admit: item.admit,
        confirm: item.confirm,
      });
      const result = await handleOcrRequest(
        {
          method: 'POST',
          path: '/v1/ocr',
          headers: item.headers ?? signed.headers,
          body: signed.body,
        },
        harness.runtime,
      );
      assert.equal(result.status, item.status, item.name);
      assert.equal(errorCode(result.body), item.code, item.name);
      assert.equal(harness.reader.calls.length, 0, item.name);
      assert.equal(result.body.includes(OCR_MARKER), false, item.name);
    }
  });

  it('rechaza magic bytes que no coinciden antes de admitir', async () => {
    const cases = [
      {
        mime: 'image/jpeg',
        body: pngBytes(),
        code: 'UNSUPPORTED_TYPE',
      },
      {
        mime: 'image/webp',
        body: Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(8)]),
        code: 'UNSUPPORTED_TYPE',
      },
      {
        mime: 'application/pdf',
        body: jpegBytes(),
        code: 'PDF_INVALID',
      },
    ];
    for (const item of cases) {
      const signed = signOcrBytes({
        body: item.body,
        mime: item.mime,
        pageCount: item.mime === 'application/pdf' ? 2 : 1,
        nonce: nonceFor(item.code.length + item.body.length),
      });
      const harness = harnessFor({ sleep: immediateSleep });
      const result = await post(harness.runtime, signed);
      assert.equal(errorCode(result.body), item.code, item.mime);
      assert.equal(harness.ledger.admits.length, 0, item.mime);
      assert.equal(harness.reader.calls.length, 0, item.mime);
    }
  });

  it('acepta PNG y WebP cuando la cabecera coincide', async () => {
    for (const item of [
      { mime: 'image/png', body: pngBytes(), nonce: nonceFor(11) },
      { mime: 'image/webp', body: webpBytes(), nonce: nonceFor(12) },
    ]) {
      const signed = signOcrBytes({
        body: item.body,
        mime: item.mime,
        pageCount: 1,
        nonce: item.nonce,
      });
      const harness = harnessFor({
        sleep: immediateSleep,
        read: okPages(['visible']),
      });
      const result = await post(harness.runtime, signed);
      assert.equal(result.status, 200, item.mime);
      assert.equal(harness.reader.calls.length, 1, item.mime);
    }
  });

  it('falla la respuesta incompleta, desordenada o discordante sin segunda llamada', async () => {
    const cases: Array<{
      name: string;
      pageCount: number;
      read: VisionReadResult;
      status: number;
      code: string;
    }> = [
      {
        name: 'faltante',
        pageCount: 2,
        read: okPages(['a']),
        status: 504,
        code: 'UNCERTAIN',
      },
      {
        name: 'duplicada',
        pageCount: 2,
        read: {
          fileErrorCode: null,
          totalPages: null,
          pages: [
            { pageNumber: 1, text: 'a', errorCode: null },
            { pageNumber: 1, text: 'b', errorCode: null },
          ],
        },
        status: 504,
        code: 'UNCERTAIN',
      },
      {
        name: 'extra',
        pageCount: 1,
        read: okPages(['a', 'b']),
        status: 504,
        code: 'UNCERTAIN',
      },
      {
        name: 'desorden',
        pageCount: 2,
        read: {
          fileErrorCode: null,
          totalPages: null,
          pages: [
            { pageNumber: 2, text: 'b', errorCode: null },
            { pageNumber: 1, text: OCR_MARKER, errorCode: null },
          ],
        },
        status: 504,
        code: 'UNCERTAIN',
      },
      {
        name: 'totalPages',
        pageCount: 1,
        read: okPages([OCR_MARKER], 4),
        status: 502,
        code: 'PAGE_COUNT_MISMATCH',
      },
      {
        name: 'error de página',
        pageCount: 1,
        read: {
          fileErrorCode: null,
          totalPages: null,
          pages: [{ pageNumber: 1, text: OCR_MARKER, errorCode: 3 }],
        },
        status: 504,
        code: 'UNCERTAIN',
      },
      {
        name: 'error de archivo',
        pageCount: 1,
        read: {
          fileErrorCode: 8,
          totalPages: 1,
          pages: [{ pageNumber: 1, text: OCR_MARKER, errorCode: null }],
        },
        status: 504,
        code: 'UNCERTAIN',
      },
      {
        name: 'vacío',
        pageCount: 1,
        read: okPages([`  \n\t${''}`]),
        status: 400,
        code: 'EMPTY_DOCUMENT',
      },
    ];
    for (const item of cases) {
      const signed = signOcrBytes({
        body: item.pageCount > 1 ? pdfBytes() : jpegBytes(),
        mime: item.pageCount > 1 ? 'application/pdf' : 'image/jpeg',
        pageCount: item.pageCount,
        nonce: nonceFor(20 + item.name.length),
      });
      const harness = harnessFor({ sleep: immediateSleep, read: item.read });
      const result = await post(harness.runtime, signed);
      assert.equal(result.status, item.status, item.name);
      assert.equal(errorCode(result.body), item.code, item.name);
      assert.equal(harness.reader.calls.length, 1, item.name);
      assert.equal(harness.ledger.completes.length, 0, item.name);
      assert.equal(harness.ledger.unknowns.length, 1, item.name);
      assert.equal(result.body.includes(OCR_MARKER), false, item.name);
      const retry = signOcrBytes({
        body: signed.body,
        mime: signed.mime,
        pageCount: signed.pageCount,
        nonce: nonceFor(40 + item.name.length),
        operationId: signed.operationId,
      });
      const again = await post(harness.runtime, retry);
      assert.equal(again.status, 409, item.name);
      assert.equal(harness.reader.calls.length, 1, item.name);
    }
  });

  it('rechaza el JSON mayor de 16 MiB sin truncarlo ni filtrar el marcador', async () => {
    const signed = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      nonce: nonceFor(51),
    });
    const harness = harnessFor({
      sleep: immediateSleep,
      read: okPages([`${OCR_MARKER}${'x'.repeat(OCR_RESPONSE_MAX_BYTES)}`]),
    });
    const result = await post(harness.runtime, signed);
    assert.equal(result.status, 504);
    assert.equal(errorCode(result.body), 'RESPONSE_TOO_LARGE');
    assert.equal(result.body.includes(OCR_MARKER), false);
    assert.equal(result.body.length < 1_024, true);
    assert.equal(harness.reader.calls.length, 1);
  });

  it('una sola llamada si el RPC o la persistencia fallan después de CALLING', async () => {
    const signed = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      nonce: nonceFor(52),
    });
    const thrown = harnessFor({
      sleep: immediateSleep,
      read: () => Promise.reject(new Error(OCR_MARKER)),
    });
    const failed = await post(thrown.runtime, signed);
    assert.equal(failed.status, 504);
    assert.equal(errorCode(failed.body), 'UNCERTAIN');
    assert.equal(failed.body.includes(OCR_MARKER), false);
    assert.equal(thrown.reader.calls.length, 1);
    const retry = signOcrBytes({
      body: signed.body,
      mime: signed.mime,
      pageCount: 1,
      nonce: nonceFor(53),
      operationId: signed.operationId,
    });
    const again = await post(thrown.runtime, retry);
    assert.equal(again.status, 409);
    assert.equal(thrown.reader.calls.length, 1);

    const both = harnessFor({
      sleep: immediateSleep,
      read: okPages([OCR_MARKER]),
      complete: { status: 'UNCERTAIN' },
      unknown: { status: 'UNCERTAIN' },
    });
    const uncertain = await post(
      both.runtime,
      signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(54),
        operationId: operationId(8),
      }),
    );
    assert.equal(uncertain.status, 504);
    assert.equal(errorCode(uncertain.body), 'UNCERTAIN');
    assert.equal(uncertain.body.includes(OCR_MARKER), false);
    assert.equal(both.ledger.completes.length, 1);
    assert.equal(both.ledger.unknowns.length, 1);
    assert.equal(both.reader.calls.length, 1);
    const second = await post(
      both.runtime,
      signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(55),
        operationId: operationId(8),
      }),
    );
    assert.equal(second.status, 409);
    assert.equal(both.reader.calls.length, 1);
  });

  it('responde en plazo si el ledger no resuelve y una admisión tardía no llama', async () => {
    let release: (value: AdmitResult) => void = () => undefined;
    const pending = new Promise<AdmitResult>((resolve) => {
      release = resolve;
    });
    const late = harnessFor({
      sleep: immediateSleep,
      admit: () => pending,
    });
    const signed = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      nonce: nonceFor(60),
    });
    const started = Date.now();
    const result = await post(late.runtime, signed);
    assert.equal(Date.now() - started < 1_000, true);
    assert.equal(result.status, 503);
    assert.equal(errorCode(result.body), 'UNAVAILABLE');
    assert.equal(late.reader.calls.length, 0);
    release({ status: 'ADMITTED', fence: 1 });
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(late.reader.calls.length, 0);

    const hung = harnessFor({
      sleep: immediateSleep,
      admit: () => new Promise<AdmitResult>(() => undefined),
    });
    const againStarted = Date.now();
    const again = await post(
      hung.runtime,
      signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(61),
        operationId: operationId(9),
      }),
    );
    assert.equal(Date.now() - againStarted < 1_000, true);
    assert.equal(again.status, 503);
    assert.equal(hung.reader.calls.length, 0);
  });

  it('el requestId no copia operationId, nonce ni digest', async () => {
    const signed = signOcrBytes({
      body: pngBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      nonce: nonceFor(70),
    });
    let draws = 0;
    const harness = harnessFor({
      sleep: immediateSleep,
      randomBytes: () => {
        draws += 1;
        return draws === 1
          ? Buffer.from(signed.nonce, 'hex')
          : Buffer.alloc(16, 4);
      },
    });
    const result = await post(harness.runtime, signed);
    const parsed = JSON.parse(result.body.toString('utf8')) as {
      requestId: string;
    };
    assert.equal(parsed.requestId, '04'.repeat(16));
    assert.notEqual(parsed.requestId, signed.operationId);
    assert.notEqual(parsed.requestId, signed.nonce);
    assert.notEqual(parsed.requestId, signed.digest);
  });

  it('readiness y una ruta distinta no tocan el ledger ni Vision', async () => {
    const harness = harnessFor({ sleep: immediateSleep });
    const ready = await handleOcrRequest(
      { method: 'GET', path: '/ready', headers: [], body: new Uint8Array() },
      harness.runtime,
    );
    assert.equal(ready.status, 200);
    assert.equal(ready.body.toString('utf8'), '{"version":"v1","ready":true}');
    const other = await handleOcrRequest(
      {
        method: 'GET',
        path: '/v1/ocr',
        headers: [],
        body: jpegBytes(),
      },
      harness.runtime,
    );
    assert.equal(other.status, 400);
    assert.equal(errorCode(other.body), 'INVALID_CONTRACT');
    assert.equal(harness.ledger.admits.length, 0);
    assert.equal(harness.reader.calls.length, 0);
    assert.equal(harness.metrics.visionCalls, 0);
  });
});

describe('servidor loopback', { concurrency: 1 }, () => {
  it('atiende un POST firmado, rechaza otra ruta y corta un cuerpo mayor de 10 MiB', async () => {
    const harness = harnessFor({
      sleep: immediateSleep,
      read: okPages([OCR_MARKER]),
    });
    const server = await listenOcr(harness.runtime);
    try {
      assert.equal(server.port > 0, true);
      const signed = signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(80),
      });
      const ok = await rawHttp(server.port, {
        method: 'POST',
        path: '/v1/ocr',
        headers: [
          ...signed.headers,
          ['Content-Type', 'application/octet-stream'],
        ],
        body: signed.body,
      });
      assert.equal(ok.status, 200);
      assert.equal(ok.body.includes(OCR_MARKER), true);
      const missing = await rawHttp(server.port, {
        method: 'POST',
        path: '/v1/nope',
        headers: [],
        body: Buffer.alloc(0),
      });
      assert.equal(missing.status, 400);
      assert.equal(JSON.parse(missing.body).code, 'INVALID_CONTRACT');
      const extra = OCR_BODY_MAX_BYTES + 1_000_000;
      const exact = Buffer.alloc(OCR_BODY_MAX_BYTES, 7);
      const signedOver = signOcrBytes({
        body: exact,
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(89),
        operationId: operationId(89),
      });
      let sent = 0;
      const oversized = await rawHttp(server.port, {
        method: 'POST',
        path: '/v1/ocr',
        headers: [
          ...signedOver.headers,
          ['Content-Type', 'application/octet-stream'],
        ],
        body: Buffer.concat([exact, Buffer.from([2])]),
        declaredLength: extra,
        onSent: (bytes) => {
          sent = bytes;
        },
      });
      assert.equal(oversized.status, 413);
      assert.equal(JSON.parse(oversized.body).code, 'PAYLOAD_TOO_LARGE');
      assert.equal(sent, OCR_BODY_MAX_BYTES + 1);
      assert.equal(harness.reader.calls.length, 1);
      assert.equal(
        harness.ledger.admits.every((item) => item.digest === signed.digest),
        true,
      );
    } finally {
      await server.close();
    }
  });
});

describe('lectura del cuerpo después de la firma', () => {
  it('acepta un POST firmado con los nombres en minúsculas', async () => {
    const harness = harnessFor({ read: okPages([OCR_MARKER]) });
    const server = await listenOcr(harness.runtime);
    try {
      const signed = signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(81),
        operationId: operationId(81),
      });
      const response = await rawHttp(server.port, {
        method: 'POST',
        path: '/v1/ocr',
        headers: signed.headers.map(
          ([name, value]) => [name.toLowerCase(), value] as [string, string],
        ),
        body: signed.body,
      });
      assert.equal(response.status, 200);
      assert.equal(response.body.includes(OCR_MARKER), true);
      assert.equal(harness.reader.calls.length, 1);
    } finally {
      await server.close();
    }
  });

  it('no lee el cuerpo si la firma del digest declarado no es válida', async () => {
    const harness = harnessFor({});
    const server = await listenOcr(harness.runtime);
    try {
      const signed = signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(82),
        operationId: operationId(82),
      });
      const headers = signed.headers.map(([name, value]) => {
        if (name !== 'X-Ocr-Signature')
          return [name, value] as [string, string];
        const last = value.endsWith('a') ? 'b' : 'a';
        return [name, `${value.slice(0, -1)}${last}`] as [string, string];
      });
      const response = await rawHttp(server.port, {
        method: 'POST',
        path: '/v1/ocr',
        headers,
        body: signed.body,
        withholdBody: true,
        responseTimeoutMs: 800,
      });
      assert.equal(response.bodyBytesWritten, 0);
      assert.equal(response.status, 401);
      assert.equal(JSON.parse(response.body).code, 'UNAUTHORIZED');
      assert.equal(harness.reader.calls.length, 0);
      assert.equal(harness.ledger.admits.length, 0);
    } finally {
      await server.close();
    }
  });

  it('corta un cliente lento en el timeout de lectura y responde el sobre', async () => {
    const harness = harnessFor({});
    const server = await listenOcr(harness.runtime, {
      bodyReadTimeoutMs: 40,
      headersTimeoutMs: 5_000,
      requestTimeoutMs: 5_000,
    });
    try {
      const signed = signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(83),
        operationId: operationId(83),
      });
      const started = Date.now();
      const response = await rawHttp(server.port, {
        method: 'POST',
        path: '/v1/ocr',
        headers: [
          ...signed.headers,
          ['Content-Type', 'application/octet-stream'],
        ],
        body: signed.body,
        dripFirstByte: true,
        responseTimeoutMs: 800,
      });
      assert.equal(Date.now() - started < 700, true);
      assert.equal(response.status, 503);
      assert.equal(JSON.parse(response.body).code, 'DISCONNECTED');
      assert.equal(response.body.includes(OCR_MARKER), false);
      assert.equal(response.bodyBytesWritten < signed.body.length, true);
      assert.equal(harness.reader.calls.length, 0);
      assert.equal(harness.ledger.admits.length, 0);
    } finally {
      await server.close();
    }
  });

  it('un header incompleto corta por headersTimeout con el sobre', async () => {
    const harness = harnessFor({});
    const server = await listenOcr(harness.runtime, {
      headersTimeoutMs: 30,
      requestTimeoutMs: 30,
      connectionsCheckingIntervalMs: 20,
    });
    try {
      const response = await partialHeaders(server.port);
      assert.equal(response.status, 503);
      assert.equal(JSON.parse(response.body).code, 'DISCONNECTED');
      assert.notEqual(response.statusLine, 'HTTP/1.1 408 Request Timeout');
    } finally {
      await server.close();
    }
  });
});

describe('recuperación de un PLANNED', () => {
  it('tras fallar confirmCalling sigue con el fence nuevo y llama una vez', async () => {
    const confirms: number[] = [];
    let admits = 0;
    const ledger = scriptedLedger({
      admit: async () => {
        admits += 1;
        return admits === 1
          ? { status: 'ADMITTED', fence: 1 }
          : { status: 'ALREADY_RESERVED', fence: 1 };
      },
      confirmCalling: async (input) => {
        confirms.push(input.fence);
        return confirms.length === 1
          ? { status: 'UNAVAILABLE' }
          : { status: 'CONFIRMED', fence: input.fence, attemptId: 'attempt-2' };
      },
      recoverPlanned: async () => ({ status: 'RECOVERED', fence: 4 }),
    });
    const calls: unknown[] = [];
    const runtime = recoveryRuntime(ledger, calls);
    const first = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      nonce: nonceFor(84),
      operationId: operationId(84),
    });
    const failed = await post(runtime, first);
    assert.equal(failed.status, 503);
    assert.equal(calls.length, 0);
    const retry = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      nonce: nonceFor(85),
      operationId: operationId(84),
    });
    const again = await post(runtime, retry);
    assert.equal(again.status, 200);
    assert.equal(calls.length, 1);
    assert.deepEqual(confirms, [1, 4]);
  });

  it('un lease vigente es CONFLICT sin RPC', async () => {
    const calls: unknown[] = [];
    let recovered = 0;
    const ledger = scriptedLedger({
      admit: async () => ({ status: 'ALREADY_RESERVED', fence: 1 }),
      recoverPlanned: async () => {
        recovered += 1;
        return { status: 'NOT_RECOVERABLE' };
      },
    });
    const result = await post(
      recoveryRuntime(ledger, calls),
      signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(86),
        operationId: operationId(86),
      }),
    );
    assert.equal(recovered, 1);
    assert.equal(result.status, 409);
    assert.equal(JSON.parse(result.body.toString('utf8')).code, 'CONFLICT');
    assert.equal(calls.length, 0);
  });

  it('recoverPlanned UNCERTAIN no llama', async () => {
    const calls: unknown[] = [];
    const ledger = scriptedLedger({
      admit: async () => ({ status: 'ALREADY_RESERVED', fence: 1 }),
      recoverPlanned: async () => ({ status: 'UNCERTAIN' }),
    });
    const result = await post(
      recoveryRuntime(ledger, calls),
      signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(87),
        operationId: operationId(87),
      }),
    );
    assert.equal(result.status, 504);
    assert.equal(JSON.parse(result.body.toString('utf8')).code, 'UNCERTAIN');
    assert.equal(calls.length, 0);
  });

  it('un CALLING no se recupera', async () => {
    const calls: unknown[] = [];
    let recovered = 0;
    const ledger = scriptedLedger({
      admit: async () => ({ status: 'ALREADY_RESERVED', fence: 2 }),
      recoverPlanned: async () => {
        recovered += 1;
        return { status: 'NOT_RECOVERABLE' };
      },
    });
    const result = await post(
      recoveryRuntime(ledger, calls),
      signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(88),
        operationId: operationId(88),
      }),
    );
    assert.equal(recovered, 1);
    assert.equal(result.status, 409);
    assert.equal(calls.length, 0);
  });
});

function immediateSleep(_ms: number, signal: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal.aborted) {
      reject(new Error('aborted'));
      return;
    }
    const timer = setTimeout(resolve, 0);
    signal.addEventListener(
      'abort',
      () => {
        clearTimeout(timer);
        reject(new Error('aborted'));
      },
      { once: true },
    );
  });
}

function okPages(
  texts: readonly string[],
  totalPages: number | null = null,
): VisionReadResult {
  return {
    totalPages,
    fileErrorCode: null,
    pages: texts.map((text, index) => ({
      pageNumber: index + 1,
      text,
      errorCode: null,
    })),
  };
}

function errorCode(body: Buffer): string {
  const parsed = JSON.parse(body.toString('utf8')) as {
    version?: string;
    code?: string;
    requestId?: string;
  };
  assert.deepEqual(Object.keys(parsed).sort(), [
    'code',
    'requestId',
    'version',
  ]);
  assert.equal(parsed.version, 'v1');
  assert.match(parsed.requestId ?? '', /^[0-9a-f]{32}$/);
  return parsed.code ?? '';
}

function post(runtime: OcrRuntime, signed: SignedOcr) {
  return handleOcrRequest(
    {
      method: 'POST',
      path: '/v1/ocr',
      headers: signed.headers,
      body: signed.body,
    },
    runtime,
  );
}

function harnessFor(input: {
  read?:
    | VisionReadResult
    | ((request: VisionReadInput) => Promise<VisionReadResult>);
  admit?: AdmitResult | (() => Promise<AdmitResult>);
  confirm?: ConfirmCallingResult;
  complete?: RecordResult;
  unknown?: RecordResult;
  sleep?: OcrRuntime['sleep'];
  randomBytes?: (size: number) => Uint8Array;
  environment?: string;
}): {
  runtime: OcrRuntime;
  ledger: {
    admits: AdmitInput[];
    completes: RecordInput[];
    unknowns: RecordInput[];
  };
  reader: { calls: VisionReadInput[] };
  logs: Array<[string, string]>;
  metrics: { requests: number; visionCalls: number; failures: number };
} {
  const admits: AdmitInput[] = [];
  const completes: RecordInput[] = [];
  const unknowns: RecordInput[] = [];
  let admitCount = 0;
  const ledger: OcrLedger = {
    async admit(entry) {
      admits.push(entry);
      admitCount += 1;
      if (admitCount > 1) return { status: 'ALREADY_RESERVED', fence: 1 };
      if (typeof input.admit === 'function') return input.admit();
      return input.admit ?? { status: 'ADMITTED', fence: 1 };
    },
    async confirmCalling() {
      return (
        input.confirm ?? {
          status: 'CONFIRMED',
          fence: 1,
          attemptId: 'attempt-1',
        }
      );
    },
    async recordComplete(entry) {
      completes.push(entry);
      return input.complete ?? { status: 'RECORDED' };
    },
    async recordUnknown(entry) {
      unknowns.push(entry);
      return input.unknown ?? { status: 'RECORDED' };
    },
    async recoverPlanned() {
      return { status: 'NOT_RECOVERABLE' };
    },
  };
  const calls: VisionReadInput[] = [];
  const reader: VisionTextReader = {
    async read(request) {
      calls.push(request);
      if (typeof input.read === 'function') return input.read(request);
      return input.read ?? okPages(['texto']);
    },
    async close() {
      return undefined;
    },
  };
  const logs: Array<[string, string]> = [];
  const metrics = { requests: 0, visionCalls: 0, failures: 0 };
  const environment = input.environment ?? 'development';
  const ring: OcrKeyRing = {
    environment,
    keys: [{ kid: 'k-current', secret: OCR_SECRET }],
  };
  return {
    runtime: {
      ring,
      ledger,
      reader,
      now: () => SIGN_NOW,
      sleep: input.sleep,
      log: (event, code) => logs.push([event, code]),
      metrics,
      randomBytes: input.randomBytes,
    },
    ledger: { admits, completes, unknowns },
    reader: { calls },
    logs,
    metrics,
  };
}

function recoveryRuntime(ledger: OcrLedger, calls: unknown[]): OcrRuntime {
  const ring: OcrKeyRing = {
    environment: 'development',
    keys: [{ kid: 'k-current', secret: OCR_SECRET }],
  };
  const reader: VisionTextReader = {
    async read(request) {
      calls.push(request);
      return okPages(['texto']);
    },
    async close() {
      return undefined;
    },
  };
  return { ring, ledger, reader, now: () => SIGN_NOW };
}

function scriptedLedger(input: {
  admit: () => Promise<AdmitResult>;
  confirmCalling?: (
    entry: ConfirmCallingInput,
  ) => Promise<ConfirmCallingResult>;
  recoverPlanned?: () => Promise<RecoverResult>;
}): OcrLedger {
  return {
    admit: () => input.admit(),
    async confirmCalling(entry) {
      return (
        input.confirmCalling?.(entry) ?? {
          status: 'CONFIRMED',
          fence: entry.fence,
          attemptId: 'attempt-1',
        }
      );
    },
    async recordComplete() {
      return { status: 'RECORDED' };
    },
    async recordUnknown() {
      return { status: 'RECORDED' };
    },
    async recoverPlanned() {
      return input.recoverPlanned?.() ?? { status: 'NOT_RECOVERABLE' };
    },
  };
}

function partialHeaders(
  port: number,
): Promise<{ status: number; body: string; statusLine: string }> {
  return new Promise((resolve, reject) => {
    const socket = net.connect({ host: '127.0.0.1', port });
    const chunks: Buffer[] = [];
    const timer = setTimeout(() => {
      socket.destroy();
      reject(new Error('timed out waiting for HTTP response'));
    }, 400);
    let settled = false;
    const finish = () => {
      if (settled) return;
      const raw = Buffer.concat(chunks);
      const split = raw.indexOf('\r\n\r\n');
      if (split < 0) return;
      const header = raw.subarray(0, split).toString('latin1');
      const statusLine = header.split('\r\n')[0] ?? '';
      const status = Number(/^HTTP\/1\.[01] (\d+)/.exec(header)?.[1]);
      const length = Number(/content-length: (\d+)/i.exec(header)?.[1] ?? 0);
      if (!Number.isInteger(status) || raw.length < split + 4 + length) return;
      settled = true;
      clearTimeout(timer);
      const body = raw.subarray(split + 4, split + 4 + length).toString('utf8');
      socket.destroy();
      resolve({ status, body, statusLine });
    };
    socket.on('data', (chunk: Buffer) => {
      chunks.push(Buffer.from(chunk));
      finish();
    });
    socket.on('error', (error) => {
      if (!settled) {
        clearTimeout(timer);
        reject(error);
      }
    });
    socket.on('close', () => {
      if (!settled) {
        clearTimeout(timer);
        reject(new Error('socket closed before the envelope'));
      }
    });
    socket.once('connect', () => {
      socket.write(
        'POST /v1/ocr HTTP/1.1\r\nHost: 127.0.0.1\r\nX-Ocr-Version: v',
      );
    });
  });
}

function rawHttp(
  port: number,
  input: {
    method: string;
    path: string;
    headers: ReadonlyArray<readonly [string, string]>;
    body: Buffer;
    declaredLength?: number;
    onSent?: (bytes: number) => void;
    withholdBody?: boolean;
    dripFirstByte?: boolean;
    responseTimeoutMs?: number;
  },
): Promise<{ status: number; body: string; bodyBytesWritten: number }> {
  return new Promise((resolve, reject) => {
    const socket = net.connect({ host: '127.0.0.1', port });
    const chunks: Buffer[] = [];
    const timer = setTimeout(() => {
      socket.destroy();
      reject(new Error('timed out waiting for HTTP response'));
    }, input.responseTimeoutMs ?? 5_000);
    let settled = false;
    let bodyBytesWritten = 0;
    const finish = () => {
      if (settled) return;
      const raw = Buffer.concat(chunks);
      const split = raw.indexOf('\r\n\r\n');
      if (split < 0) return;
      const header = raw.subarray(0, split).toString('latin1');
      const status = Number(/^HTTP\/1\.[01] (\d+)/.exec(header)?.[1]);
      const length = Number(/content-length: (\d+)/i.exec(header)?.[1] ?? 0);
      if (!Number.isInteger(status) || raw.length < split + 4 + length) return;
      settled = true;
      clearTimeout(timer);
      const body = raw.subarray(split + 4, split + 4 + length).toString('utf8');
      socket.destroy();
      resolve({ status, body, bodyBytesWritten });
    };
    socket.on('data', (chunk: Buffer) => {
      chunks.push(Buffer.from(chunk));
      finish();
    });
    socket.on('error', (error) => {
      if (chunks.length > 0) finish();
      if (!settled) {
        clearTimeout(timer);
        reject(error);
      }
    });
    socket.on('close', () => {
      if (!settled) finish();
    });
    socket.once('connect', () => {
      const length = input.declaredLength ?? input.body.length;
      const head = [
        `${input.method} ${input.path} HTTP/1.1`,
        'Host: 127.0.0.1',
        ...input.headers.map(([name, value]) => `${name}: ${value}`),
        `Content-Length: ${length}`,
        'Connection: close',
        '',
        '',
      ].join('\r\n');
      socket.write(head);
      if (input.withholdBody) return;
      const payload = input.dripFirstByte
        ? input.body.subarray(0, 1)
        : input.body;
      bodyBytesWritten = payload.length;
      socket.write(payload, () => {
        input.onSent?.(payload.length);
      });
    });
  });
}
