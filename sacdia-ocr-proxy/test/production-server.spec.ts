import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { EventEmitter } from 'node:events';
import { readFile } from 'node:fs/promises';
import { request } from 'node:http';
import net from 'node:net';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { RuntimeConfigError } from '../src/config/runtime-config.ts';
import { createOcrHttpServer } from '../src/http/ocr-server.ts';
import type { OcrLedger } from '../src/ledger/ocr-ledger.port.ts';
import type { OcrRuntime } from '../src/ocr/ocr-orchestrator.ts';
import {
  startProduction,
  type ProductionDeps,
  type ProductionHandle,
} from '../src/runtime/production.ts';
import type { VisionTextReader } from '../src/vision/vision-text-reader.ts';
import { nonceFor } from './support/ledger-sample.ts';
import {
  OCR_MARKER,
  OCR_SECRET,
  SIGN_NOW,
  jpegBytes,
  signOcrBytes,
} from './support/signed-ocr.ts';

const PACKAGE_DIR = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);
const SECRET_B64 = OCR_SECRET.toString('base64');

type FakeDb = { terminated: number; terminate(): Promise<void> };

type Harness = {
  deps: ProductionDeps<FakeDb>;
  db: FakeDb;
  calls: { firestore: string[]; ledgers: number; readers: number };
  reader: {
    reads: number;
    closes: number;
    entered: Promise<void>;
    release(): void;
  };
  signals: EventEmitter;
  exits: number[];
  logs: string[];
  admitLimits: number[];
};

function harness(options: { hold?: boolean } = {}): Harness {
  const calls = { firestore: [] as string[], ledgers: 0, readers: 0 };
  const db: FakeDb = {
    terminated: 0,
    async terminate() {
      db.terminated += 1;
    },
  };
  let markEntered: () => void = () => undefined;
  const entered = new Promise<void>((resolve) => {
    markEntered = resolve;
  });
  let releaseRead: () => void = () => undefined;
  const gate = new Promise<void>((resolve) => {
    releaseRead = resolve;
  });
  const reader = {
    reads: 0,
    closes: 0,
    entered,
    release: () => releaseRead(),
  };
  const visionReader: VisionTextReader = {
    async read() {
      reader.reads += 1;
      markEntered();
      if (options.hold) await gate;
      return {
        pages: [{ pageNumber: 1, text: OCR_MARKER, errorCode: null }],
        totalPages: null,
        fileErrorCode: null,
      };
    },
    async close() {
      reader.closes += 1;
    },
  };
  const admitLimits: number[] = [];
  const ledger: OcrLedger = {
    async admit(input) {
      admitLimits.push(input.limit);
      return { status: 'ADMITTED', fence: 1 };
    },
    async confirmCalling() {
      return { status: 'CONFIRMED', fence: 1, attemptId: 'attempt-1' };
    },
    async recordComplete() {
      return { status: 'RECORDED' };
    },
    async recordUnknown() {
      return { status: 'RECORDED' };
    },
    async recoverPlanned() {
      return { status: 'NOT_RECOVERABLE' };
    },
  };
  return {
    deps: {
      createFirestore(projectId) {
        calls.firestore.push(projectId);
        return db;
      },
      createLedger() {
        calls.ledgers += 1;
        return ledger;
      },
      createReader() {
        calls.readers += 1;
        return visionReader;
      },
    },
    db,
    calls,
    reader,
    signals: new EventEmitter(),
    exits: [],
    logs: [],
    admitLimits,
  };
}

async function freePort(): Promise<number> {
  const probe = net.createServer();
  await new Promise<void>((resolve) => probe.listen(0, '127.0.0.1', resolve));
  const address = probe.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  await new Promise<void>((resolve) => probe.close(() => resolve()));
  return port;
}

async function prodEnv(
  extra: NodeJS.ProcessEnv = {},
): Promise<NodeJS.ProcessEnv> {
  return {
    OCR_ENV: 'development',
    OCR_KID_CURRENT: 'k-current',
    OCR_SECRET_CURRENT: SECRET_B64,
    GOOGLE_CLOUD_PROJECT: 'sacdia-ocr-test',
    PORT: String(await freePort()),
    OCR_SHUTDOWN_GRACE_MS: '5000',
    ...extra,
  };
}

function boot(h: Harness, env: NodeJS.ProcessEnv): Promise<ProductionHandle> {
  return startProduction({
    env,
    deps: h.deps,
    signals: h.signals,
    exit: (code) => {
      h.exits.push(code);
    },
    log: (line) => h.logs.push(line),
    runtime: { now: () => SIGN_NOW },
  });
}

type HttpReply = { status: number; body: string };

function send(
  port: number,
  options: {
    method: string;
    path: string;
    headers?: Record<string, string>;
    body?: Buffer;
  },
): Promise<HttpReply> {
  return new Promise((resolve, reject) => {
    const req = request(
      {
        host: '127.0.0.1',
        port,
        method: options.method,
        path: options.path,
        headers: options.headers,
        agent: false,
      },
      (res) => {
        const chunks: Buffer[] = [];
        res.on('data', (chunk: Buffer) => chunks.push(chunk));
        res.on('end', () =>
          resolve({
            status: res.statusCode ?? 0,
            body: Buffer.concat(chunks).toString('utf8'),
          }),
        );
        res.on('error', reject);
      },
    );
    req.on('error', reject);
    req.end(options.body);
  });
}

function postSigned(port: number, index: number): Promise<HttpReply> {
  const signed = signOcrBytes({
    body: jpegBytes(),
    mime: 'image/jpeg',
    pageCount: 1,
    nonce: nonceFor(index),
  });
  return send(port, {
    method: 'POST',
    path: '/v1/ocr',
    headers: {
      ...Object.fromEntries(signed.headers),
      'content-type': 'application/octet-stream',
    },
    body: signed.body,
  });
}

function settled(promise: Promise<unknown>): Promise<'ok' | 'error'> {
  return promise.then(
    () => 'ok',
    () => 'error',
  );
}

/** Si el arranque no falla, cierra lo que abrió para no colgar el runner. */
async function assertStartRejects(
  h: Harness,
  env: NodeJS.ProcessEnv,
  expected: (error: unknown) => boolean,
): Promise<void> {
  let handle: ProductionHandle | undefined;
  try {
    handle = await boot(h, env);
  } catch (error) {
    assert.ok(expected(error), `error inesperado: ${String(error)}`);
    return;
  }
  h.signals.emit('SIGTERM');
  await handle.finished;
  assert.fail('el arranque debía fallar');
}

async function tick(ms = 30): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

describe('entrypoint de producción', () => {
  it('no arranca con configuración inválida y no toca Google', async () => {
    const h = harness();
    const secretEnv = await prodEnv({ OCR_ENV: 'MAL' });
    await assertStartRejects(h, secretEnv, (error) => {
      assert.ok(error instanceof RuntimeConfigError);
      assert.equal(error.message.includes(SECRET_B64), false);
      return true;
    });
    assert.deepEqual(h.calls, { firestore: [], ledgers: 0, readers: 0 });
    assert.equal(h.signals.listenerCount('SIGTERM'), 0);
    assert.equal(h.signals.listenerCount('SIGINT'), 0);
    assert.deepEqual(h.exits, []);
  });

  for (const [label, extra] of [
    ['FIRESTORE_EMULATOR_HOST', { FIRESTORE_EMULATOR_HOST: '127.0.0.1:8099' }],
    ['proyecto demo-', { GOOGLE_CLOUD_PROJECT: 'demo-ocr-local' }],
  ] as const) {
    it(`no arranca con ${label} y no construye clientes`, async () => {
      const h = harness();
      await assertStartRejects(
        h,
        await prodEnv(extra),
        (error) => error instanceof RuntimeConfigError,
      );
      assert.deepEqual(h.calls, { firestore: [], ledgers: 0, readers: 0 });
    });
  }

  it('escucha en 0.0.0.0, construye los clientes una vez y atiende /ready', async () => {
    const h = harness();
    const env = await prodEnv();
    const handle = await boot(h, env);
    try {
      assert.equal(handle.address, '0.0.0.0');
      assert.equal(handle.port, Number(env.PORT));
      assert.deepEqual(h.calls, {
        firestore: ['sacdia-ocr-test'],
        ledgers: 1,
        readers: 1,
      });
      assert.equal(h.reader.reads, 0);
      const ready = await send(handle.port, { method: 'GET', path: '/ready' });
      assert.equal(ready.status, 200);
      assert.equal(h.reader.reads, 0);
    } finally {
      h.signals.emit('SIGTERM');
      await handle.finished;
    }
  });

  it('procesa una request firmada de punta a punta con los puertos inyectados', async () => {
    const h = harness();
    const handle = await boot(h, await prodEnv());
    try {
      const reply = await postSigned(handle.port, 40);
      assert.equal(reply.status, 200);
      assert.ok(reply.body.includes(OCR_MARKER));
      assert.equal(h.reader.reads, 1);
      assert.equal(
        h.logs.some((line) => line.includes(OCR_MARKER)),
        false,
      );
    } finally {
      h.signals.emit('SIGTERM');
      await handle.finished;
    }
  });

  it('pasa el tope diario configurado a la admisión', async () => {
    const h = harness();
    const handle = await boot(
      h,
      await prodEnv({ OCR_MAX_PAGES_PER_ENV_PER_DAY: '7' }),
    );
    try {
      assert.equal((await postSigned(handle.port, 46)).status, 200);
      assert.deepEqual(h.admitLimits, [7]);
    } finally {
      h.signals.emit('SIGTERM');
      await handle.finished;
    }
  });

  it('mantiene los timeouts del servidor del handler', async () => {
    const h = harness();
    const handle = await boot(h, await prodEnv());
    try {
      assert.equal(handle.server.headersTimeout, 10_000);
      assert.equal(handle.server.requestTimeout, 35_000);
    } finally {
      h.signals.emit('SIGTERM');
      await handle.finished;
    }
  });

  it('SIGTERM sin tráfico cierra Vision y Firestore y sale con 0', async () => {
    const h = harness();
    const handle = await boot(h, await prodEnv());
    h.signals.emit('SIGTERM');
    assert.equal(await handle.finished, 0);
    assert.deepEqual(h.exits, [0]);
    assert.equal(h.reader.closes, 1);
    assert.equal(h.db.terminated, 1);
    assert.equal(h.signals.listenerCount('SIGTERM'), 0);
    assert.equal(h.signals.listenerCount('SIGINT'), 0);
    await assert.rejects(
      send(handle.port, { method: 'GET', path: '/ready' }),
      /ECONNREFUSED/,
    );
  });

  it('SIGINT también drena y sale con 0', async () => {
    const h = harness();
    const handle = await boot(h, await prodEnv());
    h.signals.emit('SIGINT');
    assert.equal(await handle.finished, 0);
    assert.deepEqual(h.exits, [0]);
    assert.equal(h.reader.closes, 1);
    assert.equal(h.db.terminated, 1);
  });

  it('SIGTERM drena: la request en curso termina y una nueva se rechaza', async () => {
    const h = harness({ hold: true });
    const handle = await boot(h, await prodEnv());
    const inflight = postSigned(handle.port, 41);
    await h.reader.entered;
    h.signals.emit('SIGTERM');
    await tick();
    assert.deepEqual(h.exits, [], 'salió con una request en curso');
    assert.equal(h.reader.closes, 0, 'cerró Vision con una request en curso');
    assert.equal(h.db.terminated, 0);
    await assert.rejects(
      send(handle.port, { method: 'GET', path: '/ready' }),
      /ECONNREFUSED/,
    );
    h.reader.release();
    const reply = await inflight;
    assert.equal(reply.status, 200);
    assert.ok(reply.body.includes(OCR_MARKER));
    assert.equal(await handle.finished, 0);
    assert.deepEqual(h.exits, [0]);
    assert.equal(h.reader.closes, 1);
    assert.equal(h.db.terminated, 1);
  });

  it('vencido el plazo fuerza la salida con la request colgada', async () => {
    const h = harness({ hold: true });
    const handle = await boot(
      h,
      await prodEnv({ OCR_SHUTDOWN_GRACE_MS: '150' }),
    );
    const inflight = postSigned(handle.port, 42);
    const inflightOutcome = settled(inflight);
    await h.reader.entered;
    const started = Date.now();
    h.signals.emit('SIGTERM');
    await tick(60);
    assert.deepEqual(h.exits, [], 'forzó antes del plazo');
    assert.equal(await handle.finished, 1);
    assert.ok(Date.now() - started >= 120, 'forzó antes del plazo');
    assert.deepEqual(h.exits, [1]);
    assert.equal(await inflightOutcome, 'error');
    h.reader.release();
  });

  it('un segundo SIGTERM fuerza la salida sin esperar el plazo', async () => {
    const h = harness({ hold: true });
    const handle = await boot(
      h,
      await prodEnv({ OCR_SHUTDOWN_GRACE_MS: '9000' }),
    );
    const inflightOutcome = settled(postSigned(handle.port, 43));
    await h.reader.entered;
    h.signals.emit('SIGTERM');
    await tick();
    assert.deepEqual(h.exits, []);
    h.signals.emit('SIGTERM');
    assert.equal(await handle.finished, 1);
    assert.deepEqual(h.exits, [1]);
    assert.equal(await inflightOutcome, 'error');
    h.reader.release();
    await tick();
    assert.deepEqual(h.exits, [1], 'salió dos veces');
  });

  it('un SIGINT después de SIGTERM también fuerza la salida', async () => {
    const h = harness({ hold: true });
    const handle = await boot(
      h,
      await prodEnv({ OCR_SHUTDOWN_GRACE_MS: '9000' }),
    );
    const inflightOutcome = settled(postSigned(handle.port, 44));
    await h.reader.entered;
    h.signals.emit('SIGTERM');
    h.signals.emit('SIGINT');
    assert.equal(await handle.finished, 1);
    assert.equal(await inflightOutcome, 'error');
    h.reader.release();
  });

  it('sale con 1 si cerrar un cliente falla después de drenar', async () => {
    const h = harness();
    h.db.terminate = async () => {
      throw new Error(`fallo con ${SECRET_B64}`);
    };
    const handle = await boot(h, await prodEnv());
    h.signals.emit('SIGTERM');
    assert.equal(await handle.finished, 1);
    assert.deepEqual(h.exits, [1]);
    assert.equal(h.reader.closes, 1);
    assert.equal(
      h.logs.some((line) => line.includes(SECRET_B64)),
      false,
    );
  });

  it('si el puerto está ocupado falla y libera los clientes creados', async () => {
    const h = harness();
    const env = await prodEnv();
    const blocker = net.createServer();
    await new Promise<void>((resolve) =>
      blocker.listen(Number(env.PORT), '0.0.0.0', resolve),
    );
    try {
      await assert.rejects(boot(h, env), /EADDRINUSE/);
      assert.equal(h.reader.closes, 1);
      assert.equal(h.db.terminated, 1);
      assert.equal(h.signals.listenerCount('SIGTERM'), 0);
      assert.deepEqual(h.exits, []);
    } finally {
      await new Promise<void>((resolve) => blocker.close(() => resolve()));
    }
  });

  it('nunca escribe secretos en los logs de arranque y cierre', async () => {
    const h = harness();
    const handle = await boot(
      h,
      await prodEnv({
        OCR_KID_PREVIOUS: 'k-old',
        OCR_SECRET_PREVIOUS: Buffer.alloc(40, 9).toString('base64'),
      }),
    );
    h.signals.emit('SIGTERM');
    await handle.finished;
    assert.ok(h.logs.length > 0);
    const text = h.logs.join('\n');
    assert.equal(text.includes(SECRET_B64), false);
    assert.equal(text.includes(Buffer.alloc(40, 9).toString('base64')), false);
  });
});

describe('guarda de drenado del servidor', () => {
  it('responde 503 sin invocar el handler cuando está drenando', async () => {
    let calls = 0;
    const runtime: OcrRuntime = {
      ring: {
        environment: 'development',
        keys: [{ kid: 'k-current', secret: OCR_SECRET }],
      },
      ledger: {
        async admit() {
          calls += 1;
          return { status: 'ADMITTED', fence: 1 };
        },
      } as unknown as OcrLedger,
      reader: {
        async read() {
          calls += 1;
          throw new Error('no debe leer');
        },
        async close() {},
      },
      now: () => SIGN_NOW,
    };
    let draining = false;
    const server = createOcrHttpServer(runtime, { draining: () => draining });
    await new Promise<void>((resolve) =>
      server.listen(0, '127.0.0.1', resolve),
    );
    const address = server.address();
    const port = typeof address === 'object' && address ? address.port : 0;
    try {
      const before = await send(port, { method: 'GET', path: '/ready' });
      assert.equal(before.status, 200);
      draining = true;
      const during = await send(port, { method: 'GET', path: '/ready' });
      assert.equal(during.status, 503);
      assert.equal(JSON.parse(during.body).code, 'UNAVAILABLE');
      const signed = signOcrBytes({
        body: jpegBytes(),
        mime: 'image/jpeg',
        pageCount: 1,
        nonce: nonceFor(45),
      });
      const post = await send(port, {
        method: 'POST',
        path: '/v1/ocr',
        headers: {
          ...Object.fromEntries(signed.headers),
          'content-type': 'application/octet-stream',
        },
        body: signed.body,
      });
      assert.equal(post.status, 503);
      assert.equal(calls, 0);
    } finally {
      server.closeAllConnections();
      await new Promise<void>((resolve) => server.close(() => resolve()));
    }
  });
});

describe('separación del entrypoint', () => {
  it('ni el runtime ni la configuración importan los SDK de Google', async () => {
    for (const file of [
      'src/runtime/production.ts',
      'src/config/runtime-config.ts',
    ]) {
      const source = await readFile(path.join(PACKAGE_DIR, file), 'utf8');
      assert.equal(/@google-cloud\//.test(source), false, file);
    }
  });

  it('listenOcr sigue forzando loopback', async () => {
    const source = await readFile(
      path.join(PACKAGE_DIR, 'src/http/ocr-server.ts'),
      'utf8',
    );
    assert.match(source, /const LOOPBACK = '127\.0\.0\.1'/);
    assert.match(source, /server\.listen\(options\.port \?\? 0, LOOPBACK/);
    assert.equal(source.includes('0.0.0.0'), false);
  });

  it('node src/main.ts carga con node directo y falla cerrado sin secretos', async () => {
    const secretEnv = {
      PATH: process.env.PATH ?? '',
      OCR_ENV: 'production',
      OCR_KID_CURRENT: 'k-current',
      OCR_SECRET_CURRENT: SECRET_B64,
      GOOGLE_CLOUD_PROJECT: 'demo-ocr-local',
      FIRESTORE_EMULATOR_HOST: '127.0.0.1:8099',
    };
    const child = spawn(process.execPath, ['src/main.ts'], {
      cwd: PACKAGE_DIR,
      env: secretEnv,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    const output: Buffer[] = [];
    child.stdout.on('data', (chunk: Buffer) => output.push(chunk));
    child.stderr.on('data', (chunk: Buffer) => output.push(chunk));
    const code = await new Promise<number | null>((resolve) =>
      child.on('exit', resolve),
    );
    const text = Buffer.concat(output).toString('utf8');
    assert.equal(code, 1, text);
    assert.ok(text.includes('FIRESTORE_EMULATOR_HOST'), text);
    assert.ok(text.includes('GOOGLE_CLOUD_PROJECT'), text);
    assert.equal(text.includes(SECRET_B64), false);
  });

  it('node src/main.ts sin entorno falla cerrado nombrando las variables', async () => {
    const child = spawn(process.execPath, ['src/main.ts'], {
      cwd: PACKAGE_DIR,
      env: { PATH: process.env.PATH ?? '' },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    const output: Buffer[] = [];
    child.stdout.on('data', (chunk: Buffer) => output.push(chunk));
    child.stderr.on('data', (chunk: Buffer) => output.push(chunk));
    const code = await new Promise<number | null>((resolve) =>
      child.on('exit', resolve),
    );
    const text = Buffer.concat(output).toString('utf8');
    assert.equal(code, 1, text);
    for (const name of [
      'OCR_ENV',
      'OCR_KID_CURRENT',
      'OCR_SECRET_CURRENT',
      'GOOGLE_CLOUD_PROJECT',
    ]) {
      assert.ok(text.includes(name), text);
    }
  });
});
