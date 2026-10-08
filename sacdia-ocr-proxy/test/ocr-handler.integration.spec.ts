import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import type { Firestore } from '@google-cloud/firestore';
import type { OcrKeyRing } from '../src/auth/ocr-signature.ts';
import type { OcrLedger } from '../src/ledger/ocr-ledger.port.ts';
import { createEmulatorFirestore } from '../src/ledger/emulator-target.ts';
import { FirestoreOcrLedger } from '../src/ledger/firestore-ocr-ledger.ts';
import { handleOcrRequest } from '../src/ocr/ocr-orchestrator.ts';
import {
  createVisionTextReader,
  type VisionCallOptions,
  type VisionClientConfig,
  type VisionClientConstructor,
} from '../src/vision/vision-text-reader.ts';
import {
  EMULATOR_HOST,
  EMULATOR_PORT,
  EMULATOR_PROJECT,
  startFirestoreEmulator,
} from './support/firestore-emulator.ts';
import { nonceFor, operationId } from './support/ledger-sample.ts';
import {
  OCR_MARKER,
  OCR_SECRET,
  SIGN_NOW,
  jpegBytes,
  pdfBytes,
  signOcrBytes,
} from './support/signed-ocr.ts';

let fakeVisionReader: ReturnType<typeof createVisionTextReader>;

describe('handler contra el emulador local', { concurrency: 1 }, () => {
  let stop = async () => {};
  let db: Firestore;
  const vision = fakeVision();

  before(async () => {
    const jar = process.env.OCR_FIRESTORE_EMULATOR_JAR;
    if (!jar) throw new Error('OCR_FIRESTORE_EMULATOR_JAR is required');
    const emulator = await startFirestoreEmulator(jar);
    stop = emulator.stop;
    db = createEmulatorFirestore({
      FIRESTORE_EMULATOR_HOST: `${EMULATOR_HOST}:${EMULATOR_PORT}`,
      GCLOUD_PROJECT: EMULATOR_PROJECT,
    });
  });

  after(async () => {
    await vision.reader.close();
    await db?.terminate().catch(() => undefined);
    await stop();
  });

  it('completa una imagen y no guarda el texto', async () => {
    const environment = env();
    const signed = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operationId(21),
      nonce: nonceFor(21),
    });
    const logs: Array<[string, string]> = [];
    const ledger = new FirestoreOcrLedger(db);
    const beforeCalls = vision.calls.length;
    const result = await handleOcrRequest(
      {
        method: 'POST',
        path: '/v1/ocr',
        headers: signed.headers,
        body: signed.body,
      },
      {
        ring: ring(environment),
        ledger,
        reader: vision.reader,
        now: () => SIGN_NOW,
        log: (event, code) => logs.push([event, code]),
      },
    );
    assert.equal(result.status, 200);
    const body = JSON.parse(result.body.toString('utf8')) as {
      pages: Array<{ text: string }>;
    };
    assert.equal(body.pages[0]?.text, OCR_MARKER);
    assert.equal(vision.calls.length, beforeCalls + 1);
    assert.equal(vision.calls.at(-1)?.method, 'images');
    assert.equal(
      vision.calls.at(-1)?.config.apiEndpoint,
      'us-vision.googleapis.com',
    );
    const stored = await ledger.readDocument(
      'operations',
      environment,
      signed.operationId,
    );
    assert.equal(stored?.state, 'COMPLETE');
    assert.equal(JSON.stringify(stored).includes(OCR_MARKER), false);
    assert.equal(JSON.stringify(logs).includes(OCR_MARKER), false);
  });

  it('completa un PDF de 5 con las páginas pedidas en orden', async () => {
    const environment = env();
    const signed = signOcrBytes({
      body: pdfBytes(),
      mime: 'application/pdf',
      pageCount: 5,
      environment,
      operationId: operationId(22),
      nonce: nonceFor(22),
    });
    const ledger = new FirestoreOcrLedger(db);
    const beforeCalls = vision.calls.length;
    const result = await handleOcrRequest(
      {
        method: 'POST',
        path: '/v1/ocr',
        headers: signed.headers,
        body: signed.body,
      },
      runtime(environment, ledger),
    );
    assert.equal(result.status, 200);
    const body = JSON.parse(result.body.toString('utf8')) as {
      pageCount: number;
      pages: Array<{ pageNumber: number; text: string }>;
    };
    assert.equal(body.pageCount, 5);
    assert.deepEqual(
      body.pages.map((page) => page.pageNumber),
      [1, 2, 3, 4, 5],
    );
    assert.equal(body.pages[0]?.text.includes(OCR_MARKER), true);
    const call = vision.calls[beforeCalls];
    assert.equal(call?.method, 'files');
    const request = call?.request as {
      requests: Array<{ pages: number[] }>;
    };
    assert.deepEqual(request.requests[0]?.pages, [1, 2, 3, 4, 5]);
    assert.deepEqual(call?.options, {
      timeout: 25_000,
      retry: { retryCodes: [] },
    });
    const stored = await ledger.readDocument(
      'operations',
      environment,
      signed.operationId,
    );
    assert.equal(stored?.state, 'COMPLETE');
    assert.equal(JSON.stringify(stored).includes(OCR_MARKER), false);
  });

  it('el replay del nonce no vuelve a llamar', async () => {
    const environment = env();
    const ledger = new FirestoreOcrLedger(db);
    const first = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operationId(23),
      nonce: nonceFor(23),
    });
    const beforeCalls = vision.calls.length;
    const ok = await handleOcrRequest(
      {
        method: 'POST',
        path: '/v1/ocr',
        headers: first.headers,
        body: first.body,
      },
      runtime(environment, ledger),
    );
    assert.equal(ok.status, 200);
    const replay = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operationId(24),
      nonce: nonceFor(23),
    });
    const again = await handleOcrRequest(
      {
        method: 'POST',
        path: '/v1/ocr',
        headers: replay.headers,
        body: replay.body,
      },
      runtime(environment, ledger),
    );
    assert.equal(again.status, 401);
    assert.equal(JSON.parse(again.body.toString('utf8')).code, 'UNAUTHORIZED');
    assert.equal(vision.calls.length, beforeCalls + 1);
    assert.equal(again.body.includes(OCR_MARKER), false);
  });

  it('la cuota agotada no llama', async () => {
    const environment = env();
    const ledger = new FirestoreOcrLedger(db);
    const beforeCalls = vision.calls.length;
    const first = await handleOcrRequest(
      {
        method: 'POST',
        path: '/v1/ocr',
        headers: signOcrBytes({
          body: jpegBytes(),
          mime: 'image/jpeg',
          pageCount: 1,
          environment,
          operationId: operationId(25),
          nonce: nonceFor(25),
        }).headers,
        body: jpegBytes(),
      },
      { ...runtime(environment, ledger), pageLimit: 1 },
    );
    assert.equal(first.status, 200);
    const second = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operationId(26),
      nonce: nonceFor(26),
    });
    const blocked = await handleOcrRequest(
      {
        method: 'POST',
        path: '/v1/ocr',
        headers: second.headers,
        body: second.body,
      },
      { ...runtime(environment, ledger), pageLimit: 1 },
    );
    assert.equal(blocked.status, 429);
    assert.equal(JSON.parse(blocked.body.toString('utf8')).code, 'QUOTA');
    assert.equal(vision.calls.length, beforeCalls + 1);
  });

  it('después de CALLING el reintento no llama otra vez', async () => {
    const environment = env();
    const ledger = new FirestoreOcrLedger(db);
    vision.failNext = true;
    const beforeCalls = vision.calls.length;
    const signed = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operationId(27),
      nonce: nonceFor(27),
    });
    const failed = await handleOcrRequest(
      {
        method: 'POST',
        path: '/v1/ocr',
        headers: signed.headers,
        body: signed.body,
      },
      runtime(environment, ledger),
    );
    assert.equal(failed.status, 504);
    assert.equal(JSON.parse(failed.body.toString('utf8')).code, 'UNCERTAIN');
    assert.equal(failed.body.includes(OCR_MARKER), false);
    const stored = await ledger.readDocument(
      'operations',
      environment,
      signed.operationId,
    );
    assert.equal(stored?.state, 'UNKNOWN');
    assert.equal(JSON.stringify(stored).includes(OCR_MARKER), false);
    const retry = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: signed.operationId,
      nonce: nonceFor(28),
    });
    const again = await handleOcrRequest(
      {
        method: 'POST',
        path: '/v1/ocr',
        headers: retry.headers,
        body: retry.body,
      },
      runtime(environment, ledger),
    );
    assert.equal(again.status, 409);
    assert.equal(vision.calls.length, beforeCalls + 1);
  });

  it('recupera un PLANNED con lease vencido y hace una sola llamada', async () => {
    const environment = env();
    const inner = new FirestoreOcrLedger(db);
    const ledger = failFirstConfirm(inner);
    let clock = SIGN_NOW;
    const beforeCalls = vision.calls.length;
    const operation = operationId(40);
    const first = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operation,
      nonce: nonceFor(40),
    });
    const failed = await handleOcrRequest(requestOf(first), {
      ...runtime(environment, inner),
      ledger,
      now: () => clock,
    });
    assert.equal(failed.status, 503);
    assert.equal(vision.calls.length, beforeCalls);
    const planned = await inner.readDocument(
      'operations',
      environment,
      operation,
    );
    assert.equal(planned?.state, 'PLANNED');
    clock = new Date(SIGN_NOW.getTime() + 61_000);
    const retry = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operation,
      nonce: nonceFor(41),
    });
    const again = await handleOcrRequest(requestOf(retry), {
      ...runtime(environment, inner),
      ledger,
      now: () => clock,
    });
    assert.equal(again.status, 200);
    assert.equal(vision.calls.length, beforeCalls + 1);
    const stored = await inner.readDocument(
      'operations',
      environment,
      operation,
    );
    assert.equal(stored?.state, 'COMPLETE');
    assert.equal(stored?.fence, 2);
    assert.equal(JSON.stringify(stored).includes(OCR_MARKER), false);
  });

  it('un lease vigente responde CONFLICT sin RPC', async () => {
    const environment = env();
    const inner = new FirestoreOcrLedger(db);
    const ledger = failFirstConfirm(inner);
    let clock = SIGN_NOW;
    const beforeCalls = vision.calls.length;
    const operation = operationId(42);
    const first = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operation,
      nonce: nonceFor(42),
    });
    const failed = await handleOcrRequest(requestOf(first), {
      ...runtime(environment, inner),
      ledger,
      now: () => clock,
    });
    assert.equal(failed.status, 503);
    assert.equal(vision.calls.length, beforeCalls);
    clock = new Date(SIGN_NOW.getTime() + 1_000);
    const retry = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operation,
      nonce: nonceFor(43),
    });
    const again = await handleOcrRequest(requestOf(retry), {
      ...runtime(environment, inner),
      ledger,
      now: () => clock,
    });
    assert.equal(again.status, 409);
    assert.equal(JSON.parse(again.body.toString('utf8')).code, 'CONFLICT');
    assert.equal(vision.calls.length, beforeCalls);
    const stored = await inner.readDocument(
      'operations',
      environment,
      operation,
    );
    assert.equal(stored?.state, 'PLANNED');
    assert.equal(stored?.fence, 1);
  });

  it('una operación en CALLING no se recupera', async () => {
    const environment = env();
    const inner = new FirestoreOcrLedger(db);
    const ledger = keepCalling(inner);
    vision.failNext = true;
    const beforeCalls = vision.calls.length;
    const operation = operationId(44);
    const first = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operation,
      nonce: nonceFor(44),
    });
    const failed = await handleOcrRequest(
      requestOf(first),
      runtime(environment, ledger),
    );
    assert.equal(failed.status, 504);
    assert.equal(failed.body.includes(OCR_MARKER), false);
    assert.equal(vision.calls.length, beforeCalls + 1);
    const calling = await inner.readDocument(
      'operations',
      environment,
      operation,
    );
    assert.equal(calling?.state, 'CALLING');
    const retry = signOcrBytes({
      body: jpegBytes(),
      mime: 'image/jpeg',
      pageCount: 1,
      environment,
      operationId: operation,
      nonce: nonceFor(45),
    });
    const again = await handleOcrRequest(
      requestOf(retry),
      runtime(environment, ledger),
    );
    assert.equal(again.status, 409);
    assert.equal(JSON.parse(again.body.toString('utf8')).code, 'CONFLICT');
    assert.equal(vision.calls.length, beforeCalls + 1);
    const stored = await inner.readDocument(
      'operations',
      environment,
      operation,
    );
    assert.equal(stored?.state, 'CALLING');
    assert.equal(stored?.fence, calling?.fence);
  });
});

let environmentCounter = 30;

function env(): string {
  environmentCounter += 1;
  return `env${environmentCounter.toString(16).padStart(2, '0')}`;
}

function ring(environment: string): OcrKeyRing {
  return {
    environment,
    keys: [{ kid: 'k-current', secret: OCR_SECRET }],
  };
}

function requestOf(signed: {
  headers: ReturnType<typeof signOcrBytes>['headers'];
  body: Buffer;
}) {
  return {
    method: 'POST' as const,
    path: '/v1/ocr',
    headers: signed.headers,
    body: signed.body,
  };
}

function failFirstConfirm(inner: FirestoreOcrLedger): OcrLedger {
  let confirms = 0;
  return {
    admit: (input) => inner.admit(input),
    confirmCalling: (input) => {
      confirms += 1;
      if (confirms === 1) return Promise.resolve({ status: 'UNAVAILABLE' });
      return inner.confirmCalling(input);
    },
    recoverPlanned: (input) => inner.recoverPlanned(input),
    recordComplete: (input) => inner.recordComplete(input),
    recordUnknown: (input) => inner.recordUnknown(input),
  };
}

function keepCalling(inner: FirestoreOcrLedger): OcrLedger {
  return {
    admit: (input) => inner.admit(input),
    confirmCalling: (input) => inner.confirmCalling(input),
    recoverPlanned: (input) => inner.recoverPlanned(input),
    async recordComplete() {
      return { status: 'UNCERTAIN' };
    },
    async recordUnknown() {
      return { status: 'UNCERTAIN' };
    },
  };
}

function runtime(environment: string, ledger: OcrLedger) {
  return {
    ring: ring(environment),
    ledger,
    reader: fakeVisionReader,
    now: () => SIGN_NOW,
  };
}

function fakeVision(): {
  reader: ReturnType<typeof createVisionTextReader>;
  calls: Array<{
    method: string;
    request: unknown;
    options: VisionCallOptions;
    config: VisionClientConfig;
  }>;
  failNext: boolean;
} {
  const calls: Array<{
    method: string;
    request: unknown;
    options: VisionCallOptions;
    config: VisionClientConfig;
  }> = [];
  const state = { failNext: false };
  class Client {
    config: VisionClientConfig;

    constructor(config: VisionClientConfig) {
      this.config = config;
    }

    async batchAnnotateImages(request: unknown, options: VisionCallOptions) {
      calls.push({
        method: 'images',
        request,
        options,
        config: this.config,
      });
      if (state.failNext) {
        state.failNext = false;
        throw new Error(OCR_MARKER);
      }
      return [{ responses: [{ fullTextAnnotation: { text: OCR_MARKER } }] }];
    }

    async batchAnnotateFiles(request: unknown, options: VisionCallOptions) {
      calls.push({
        method: 'files',
        request,
        options,
        config: this.config,
      });
      return [
        {
          responses: [
            {
              totalPages: 5,
              responses: [1, 2, 3, 4, 5].map((pageNumber) => ({
                context: { pageNumber },
                fullTextAnnotation: { text: `${OCR_MARKER}-${pageNumber}` },
              })),
            },
          ],
        },
      ];
    }

    close() {
      return undefined;
    }
  }
  const reader = createVisionTextReader({
    Client: Client as unknown as VisionClientConstructor,
  });
  fakeVisionReader = reader;
  return {
    reader,
    calls,
    get failNext() {
      return state.failNext;
    },
    set failNext(value: boolean) {
      state.failNext = value;
    },
  };
}
