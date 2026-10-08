import assert from 'node:assert/strict';
import { createHash, createHmac } from 'node:crypto';
import { Buffer } from 'node:buffer';
import { createRequire } from 'node:module';
import net from 'node:net';
import { after, before, describe, it } from 'node:test';
import type { Firestore } from '@google-cloud/firestore';
import { verifyOcrRequest } from '../src/auth/ocr-signature.ts';
import { createEmulatorFirestore } from '../src/ledger/emulator-target.ts';
import { FirestoreOcrLedger } from '../src/ledger/firestore-ocr-ledger.ts';
import type { AdmitInput } from '../src/ledger/ocr-ledger.port.ts';
import {
  admitOperation,
  callAfterDurableCalling,
} from '../src/ocr/ocr-admission.ts';
import { OCR_HEADERS } from '../src/ocr/ocr-contract.ts';
import { utcDay } from '../src/ledger/ocr-ledger-time.ts';
import {
  DIGEST,
  ISSUED_AT,
  NONCE,
  NOW,
  OTHER_DIGEST,
  nonceFor,
  operationId,
} from './support/ledger-sample.ts';
import {
  EMULATOR_HOST,
  EMULATOR_PORT,
  EMULATOR_PROJECT,
  startFirestoreEmulator,
} from './support/firestore-emulator.ts';

const FORBIDDEN = [
  'text',
  'ocrText',
  'email',
  'userId',
  'objectKey',
  'url',
  'certificate',
  'secret',
];

describe(
  'ledger Firestore contra el emulador local',
  { concurrency: 1 },
  () => {
    let stop = async () => {};
    let db: Firestore;

    before(async () => {
      const jar = process.env.OCR_FIRESTORE_EMULATOR_JAR;
      if (!jar) throw new Error('OCR_FIRESTORE_EMULATOR_JAR is required');
      await assertOccupiedPortRejected(jar);
      const emulator = await startFirestoreEmulator(jar);
      stop = emulator.stop;
      db = createEmulatorFirestore({
        FIRESTORE_EMULATOR_HOST: `${EMULATOR_HOST}:${EMULATOR_PORT}`,
        GCLOUD_PROJECT: EMULATOR_PROJECT,
      });
    });

    after(async () => {
      await db?.terminate().catch(() => undefined);
      await stop();
    });

    it('no busca ADC ni renueva tokens al admitir', async () => {
      const probes = watchAmbientAuth();
      try {
        const ledger = new FirestoreOcrLedger(db);
        const admitted = await ledger.admit(admit(env()));
        assert.equal(admitted.status, 'ADMITTED');
        assert.deepEqual(probes.counts(), {
          adc: 0,
          refresh: 0,
        });
      } finally {
        probes.restore();
      }
    });

    it('admite una sola vez el mismo operationId y el mismo nonce', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const input = admit(environment);
      const [first, second] = await Promise.all([
        ledger.admit(input),
        ledger.admit({ ...input, nonce: nonceFor(2) }),
      ]);
      const statuses = [first.status, second.status].sort();
      assert.deepEqual(statuses, ['ADMITTED', 'ALREADY_RESERVED']);
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 1);

      const replay = await ledger.admit({
        ...input,
        operationId: operationId(9),
        nonce: input.nonce,
      });
      assert.equal(replay.status, 'REPLAY');
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 1);
    });

    it('rechaza otro digest sin reservar de nuevo', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const input = admit(environment, {
        pageCount: 5,
        mime: 'application/pdf',
      });
      const admitted = await ledger.admit(input);
      assert.equal(admitted.status, 'ADMITTED');
      const conflict = await ledger.admit({
        ...input,
        digest: OTHER_DIGEST,
        nonce: nonceFor(3),
      });
      assert.equal(conflict.status, 'CONFLICT');
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 5);
      const stored = await ledger.readDocument(
        'operations',
        environment,
        input.operationId,
      );
      assert.equal(stored?.digest, DIGEST);
      assertMetadata(stored);
    });

    it('el mismo operationId con otro conteo firmado es CONFLICT', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const first = verifySignedCount('5', nonceFor(70), environment);
      assert.equal(first.ok, true);
      if (!first.ok) return;
      const admitted = await admitOperation(
        ledger,
        400,
        first,
        signedAdmit(environment, nonceFor(70), 1),
      );
      assert.equal(admitted.status, 'ADMITTED');
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 5);
      const second = verifySignedCount('3', nonceFor(71), environment);
      assert.equal(second.ok, true);
      if (!second.ok) return;
      const conflict = await admitOperation(
        ledger,
        400,
        second,
        signedAdmit(environment, nonceFor(71), 1),
      );
      assert.equal(conflict.status, 'CONFLICT');
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 5);
    });

    it('no comparte la cuota entre entornos', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const left = env();
      const right = env();
      await ledger.admit(admit(left, { limit: 1 }));
      const other = await ledger.admit(
        admit(right, { limit: 1, nonce: nonceFor(4) }),
      );
      assert.equal(other.status, 'ADMITTED');
      assert.equal(await ledger.reservedPages(left, utcDay(NOW)), 1);
      assert.equal(await ledger.reservedPages(right, utcDay(NOW)), 1);
    });

    it(
      'reserva 400, rechaza la 401 y no parte un PDF',
      { timeout: 180_000 },
      async () => {
        const ledger = new FirestoreOcrLedger(db);
        const environment = env();
        for (let index = 0; index < 400; index += 1) {
          const result = await ledger.admit(
            admit(environment, {
              operationId: operationId(index + 1),
              nonce: nonceFor(index + 1),
              limit: 400,
            }),
          );
          assert.equal(result.status, 'ADMITTED');
        }
        const overflow = await ledger.admit(
          admit(environment, {
            operationId: operationId(401),
            nonce: nonceFor(401),
            limit: 400,
          }),
        );
        assert.equal(overflow.status, 'QUOTA');
        assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 400);

        const partial = env();
        await ledger.admit(
          admit(partial, { limit: 5, pageCount: 3, nonce: nonceFor(10) }),
        );
        const rejected = await ledger.admit(
          admit(partial, {
            limit: 5,
            pageCount: 3,
            operationId: operationId(11),
            nonce: nonceFor(11),
            mime: 'application/pdf',
          }),
        );
        assert.equal(rejected.status, 'QUOTA');
        assert.equal(await ledger.reservedPages(partial, utcDay(NOW)), 3);
      },
    );

    it('no duplica la reserva en un retry ni al cruzar el día UTC', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const input = admit(environment);
      await ledger.admit(input);
      const retry = await ledger.admit({
        ...input,
        nonce: nonceFor(12),
        now: new Date('2026-10-03T00:30:00.000Z'),
      });
      assert.equal(retry.status, 'ALREADY_RESERVED');
      assert.equal(await ledger.reservedPages(environment, '2026-10-02'), 1);
      assert.equal(await ledger.reservedPages(environment, '2026-10-03'), 0);
    });

    it('no reserva con límite inválido ni con reloj inválido', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const invalid = await ledger.admit(admit(environment, { limit: 0 }));
      assert.equal(invalid.status, 'INVALID_CONTRACT');
      const clock = await ledger.admit(
        admit(environment, { now: new Date(Number.NaN), nonce: nonceFor(13) }),
      );
      assert.equal(clock.status, 'INVALID_CONTRACT');
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 0);
    });

    it('conserva la reserva PLANNED y no llama al efecto sin CALLING', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const admitted = await ledger.admit(admit(environment));
      assert.equal(admitted.status, 'ADMITTED');
      let effects = 0;
      const called = await callAfterDurableCalling(
        () =>
          ledger.confirmCalling({
            environment,
            operationId: operationId(1),
            fence: 99,
            now: NOW,
          }),
        () => {
          effects += 1;
        },
      );
      assert.equal(called, 'NOT_CALLED');
      assert.equal(effects, 0);
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 1);
      const stored = await ledger.readDocument(
        'operations',
        environment,
        operationId(1),
      );
      assert.equal(stored?.state, 'PLANNED');
    });

    it('confirma CALLING una sola vez y un fence viejo no llama', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const admitted = await ledger.admit(
        admit(environment, { leaseMs: 1_000 }),
      );
      assert.equal(admitted.status, 'ADMITTED');
      if (admitted.status !== 'ADMITTED') return;
      const recovered = await ledger.recoverPlanned({
        environment,
        operationId: operationId(1),
        now: new Date(NOW.getTime() + 1_001),
      });
      assert.equal(recovered.status, 'RECOVERED');
      if (recovered.status !== 'RECOVERED') return;
      let effects = 0;
      const lost = await callAfterDurableCalling(
        () =>
          ledger.confirmCalling({
            environment,
            operationId: operationId(1),
            fence: admitted.fence,
            now: new Date(NOW.getTime() + 1_001),
          }),
        () => {
          effects += 1;
        },
      );
      assert.equal(lost, 'NOT_CALLED');
      const won = await callAfterDurableCalling(
        () =>
          ledger.confirmCalling({
            environment,
            operationId: operationId(1),
            fence: recovered.fence,
            now: new Date(NOW.getTime() + 1_001),
          }),
        () => {
          effects += 1;
        },
      );
      assert.equal(won, 'CALLED');
      assert.equal(effects, 1);
      const stored = await ledger.readDocument(
        'operations',
        environment,
        operationId(1),
      );
      assert.equal(stored?.state, 'CALLING');
      assertMetadata(stored);
    });

    it('relee un commit ambiguo y no llama si la relectura falla', async () => {
      const environment = env();
      let faults = 1;
      const ledger = new FirestoreOcrLedger(db, {
        afterCommit(kind) {
          if (kind === 'confirmCalling' && faults > 0) {
            faults -= 1;
            const error = new Error('deadline') as Error & { code: number };
            error.code = 4;
            throw error;
          }
        },
      });
      const admitted = await ledger.admit(admit(environment));
      assert.equal(admitted.status, 'ADMITTED');
      if (admitted.status !== 'ADMITTED') return;
      let effects = 0;
      const called = await callAfterDurableCalling(
        () =>
          ledger.confirmCalling({
            environment,
            operationId: operationId(1),
            fence: admitted.fence,
            now: NOW,
          }),
        () => {
          effects += 1;
        },
      );
      assert.equal(called, 'CALLED');
      assert.equal(effects, 1);

      const blocked = env();
      const uncertain = new FirestoreOcrLedger(db, {
        afterCommit(kind) {
          if (kind === 'confirmCalling') {
            const error = new Error('unavailable') as Error & { code: number };
            error.code = 14;
            throw error;
          }
        },
        failReread: true,
      });
      const second = await uncertain.admit(admit(blocked));
      assert.equal(second.status, 'ADMITTED');
      if (second.status !== 'ADMITTED') return;
      let blockedEffects = 0;
      const skipped = await callAfterDurableCalling(
        () =>
          uncertain.confirmCalling({
            environment: blocked,
            operationId: operationId(1),
            fence: second.fence,
            now: NOW,
          }),
        () => {
          blockedEffects += 1;
        },
      );
      assert.equal(skipped, 'NOT_CALLED');
      assert.equal(blockedEffects, 0);
      assert.equal(await uncertain.reservedPages(blocked, utcDay(NOW)), 1);
    });

    it('no repite el callback de transacción como una segunda reserva', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const input = admit(environment, {
        pageCount: 5,
        mime: 'application/pdf',
      });
      await db.runTransaction(async (tx) => {
        const first = await ledger.stageAdmission(tx, input);
        const second = await ledger.stageAdmission(tx, input);
        assert.equal(first.status, 'ADMITTED');
        assert.equal(second.status, 'ALREADY_RESERVED');
      });
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 5);
    });

    it('marca COMPLETE sin texto y UNKNOWN no vuelve a CALLING', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const admitted = await ledger.admit(admit(environment));
      assert.equal(admitted.status, 'ADMITTED');
      if (admitted.status !== 'ADMITTED') return;
      const calling = await ledger.confirmCalling({
        environment,
        operationId: operationId(1),
        fence: admitted.fence,
        now: NOW,
      });
      assert.equal(calling.status, 'CONFIRMED');
      if (calling.status !== 'CONFIRMED') return;
      const recorded = await ledger.recordComplete({
        environment,
        operationId: operationId(1),
        attemptId: calling.attemptId,
        now: NOW,
      });
      assert.equal(recorded.status, 'RECORDED');
      const complete = await ledger.readDocument(
        'operations',
        environment,
        operationId(1),
      );
      assert.equal(complete?.state, 'COMPLETE');
      assertMetadata(complete);

      const other = env();
      const planned = await ledger.admit(admit(other));
      assert.equal(planned.status, 'ADMITTED');
      if (planned.status !== 'ADMITTED') return;
      const started = await ledger.confirmCalling({
        environment: other,
        operationId: operationId(1),
        fence: planned.fence,
        now: NOW,
      });
      assert.equal(started.status, 'CONFIRMED');
      if (started.status !== 'CONFIRMED') return;
      const unknown = await ledger.recordUnknown({
        environment: other,
        operationId: operationId(1),
        attemptId: started.attemptId,
        now: NOW,
      });
      assert.equal(unknown.status, 'RECORDED');
      const again = await ledger.confirmCalling({
        environment: other,
        operationId: operationId(1),
        fence: planned.fence,
        now: NOW,
      });
      assert.equal(again.status, 'LOST_FENCE');
      const recovered = await ledger.recoverPlanned({
        environment: other,
        operationId: operationId(1),
        now: new Date(NOW.getTime() + 120_000),
      });
      assert.equal(recovered.status, 'NOT_RECOVERABLE');
    });

    it('sigue rechazando nonce y operación vencidos que todavía existen', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const old = new Date(NOW.getTime() - 8 * 24 * 60 * 60 * 1000);
      const expired = await ledger.admit(
        admit(environment, { issuedAt: old.toISOString(), now: NOW }),
      );
      assert.equal(expired.status, 'EXPIRED');
      assert.equal(await ledger.reservedPages(environment, utcDay(NOW)), 0);

      const kept = env();
      await ledger.admit(admit(kept));
      const beforeRetain = new Date(NOW.getTime() + 240_000 + 300_000 - 1);
      const earlyNonce = await ledger.purgeIfEligible({
        environment: kept,
        now: beforeRetain,
        operationIds: [],
        nonces: [NONCE],
        quotaDays: [],
      });
      assert.equal(earlyNonce.deleted, 0);
      const replay = await ledger.admit(
        admit(kept, { operationId: operationId(2), nonce: NONCE }),
      );
      assert.equal(replay.status, 'REPLAY');
      const earlyOperation = await ledger.purgeIfEligible({
        environment: kept,
        now: new Date(NOW.getTime() + 8 * 24 * 60 * 60 * 1000 - 1),
        operationIds: [operationId(1)],
        nonces: [],
        quotaDays: [utcDay(NOW)],
      });
      assert.equal(earlyOperation.deleted, 0);
      const purged = await ledger.purgeIfEligible({
        environment: kept,
        now: new Date(NOW.getTime() + 240_000 + 300_000),
        operationIds: [],
        nonces: [NONCE],
        quotaDays: [],
      });
      assert.equal(purged.deleted, 1);
      const stillThere = await ledger.readDocument(
        'operations',
        kept,
        operationId(1),
      );
      assert.equal(stillThere?.state, 'PLANNED');
    });

    it('devuelve UNAVAILABLE si el emulador no escucha, sin cliente cloud', async () => {
      const down = createEmulatorFirestore({
        FIRESTORE_EMULATOR_HOST: '127.0.0.1:1',
        GCLOUD_PROJECT: 'demo-ocr-down',
      });
      const ledger = new FirestoreOcrLedger(down);
      const result = await ledger.admit(admit(env()));
      assert.equal(result.status, 'UNAVAILABLE');
      await down.terminate().catch(() => undefined);
    });
  },
);

let environmentCounter = 0;

function env(): string {
  environmentCounter += 1;
  return `env${environmentCounter.toString(16).padStart(2, '0')}`;
}

const SIGNED_SECRET = Buffer.from('0123456789abcdef0123456789abcdef');
const SIGNED_BODY = Buffer.from('synthetic certificate');

function verifySignedCount(
  pageCountText: string,
  nonce: string,
  environment: string,
) {
  const contentSha256 = createHash('sha256').update(SIGNED_BODY).digest('hex');
  const signature = createHmac('sha256', SIGNED_SECRET)
    .update(
      [
        'v1',
        'POST',
        '/v1/ocr',
        environment,
        'k-current',
        operationId(1),
        ISSUED_AT,
        'application/pdf',
        String(SIGNED_BODY.length),
        pageCountText,
        '1759420000',
        nonce,
        contentSha256,
      ].join('\n') + '\n',
    )
    .digest('hex');
  return verifyOcrRequest({
    ring: {
      environment,
      keys: [{ kid: 'k-current', secret: SIGNED_SECRET }],
    },
    method: 'POST',
    path: '/v1/ocr',
    headers: [
      [OCR_HEADERS.version, 'v1'],
      [OCR_HEADERS.environment, environment],
      [OCR_HEADERS.kid, 'k-current'],
      [OCR_HEADERS.operationId, operationId(1)],
      [OCR_HEADERS.issuedAt, ISSUED_AT],
      [OCR_HEADERS.contentType, 'application/pdf'],
      [OCR_HEADERS.contentLength, String(SIGNED_BODY.length)],
      ['X-Ocr-Page-Count', pageCountText],
      [OCR_HEADERS.timestamp, '1759420000'],
      [OCR_HEADERS.nonce, nonce],
      [OCR_HEADERS.contentSha256, contentSha256],
      [OCR_HEADERS.signature, signature],
    ],
    body: SIGNED_BODY,
    now: new Date(1_759_420_000 * 1000),
  });
}

function signedAdmit(
  environment: string,
  nonce: string,
  decoyPageCount: number,
): Omit<AdmitInput, 'limit'> {
  return {
    environment,
    operationId: operationId(1),
    issuedAt: ISSUED_AT,
    digest: DIGEST,
    mime: 'application/pdf',
    byteLength: SIGNED_BODY.length,
    pageCount: decoyPageCount,
    nonce,
    requestTimestamp: 1_759_420_000,
    receivedAt: NOW,
    now: NOW,
  };
}

function admit(
  environment: string,
  over: Partial<AdmitInput> = {},
): AdmitInput {
  return {
    environment,
    operationId: operationId(1),
    issuedAt: ISSUED_AT,
    digest: DIGEST,
    mime: 'image/jpeg',
    byteLength: 21,
    pageCount: 1,
    nonce: NONCE,
    requestTimestamp: Math.floor(NOW.getTime() / 1000),
    receivedAt: NOW,
    now: NOW,
    limit: 400,
    ...over,
  };
}

function assertMetadata(stored: Record<string, unknown> | null): void {
  assert.ok(stored);
  for (const key of Object.keys(stored ?? {})) {
    assert.equal(FORBIDDEN.includes(key), false, key);
  }
}

async function assertOccupiedPortRejected(jar: string): Promise<void> {
  const server = net.createServer();
  let accepted = 0;
  server.on('connection', (socket) => {
    accepted += 1;
    socket.destroy();
  });
  await new Promise<void>((resolve, reject) => {
    server.once('error', reject);
    server.listen(EMULATOR_PORT, EMULATOR_HOST, () => resolve());
  });
  let started: { stop: () => Promise<void> } | undefined;
  try {
    await assert.rejects(async () => {
      started = await startFirestoreEmulator(jar);
    }, /already in use/);
    assert.equal(accepted, 0);
  } finally {
    await started?.stop();
    await new Promise<void>((resolve) => {
      server.close(() => resolve());
    });
  }
}

const requireAuth = createRequire(import.meta.url);
const ambientAuth = requireAuth('google-auth-library') as {
  GoogleAuth: { prototype: Record<string, unknown> };
  OAuth2Client: { prototype: Record<string, unknown> };
};

function watchAmbientAuth(): {
  counts: () => { adc: number; refresh: number };
  restore: () => void;
} {
  const adc = { count: 0 };
  const refresh = { count: 0 };
  const restoreAdc = arm(
    ambientAuth.GoogleAuth.prototype,
    [
      'getClient',
      'getApplicationDefaultAsync',
      'getRequestHeaders',
      'getAccessToken',
      '_tryGetApplicationCredentialsFromEnvironmentVariable',
      '_tryGetApplicationCredentialsFromWellKnownFile',
      '_checkIsGCE',
    ],
    adc,
  );
  const restoreRefresh = arm(
    ambientAuth.OAuth2Client.prototype,
    ['refreshToken', 'refreshTokenNoCache', 'getAccessToken', 'getToken'],
    refresh,
  );
  return {
    counts: () => ({ adc: adc.count, refresh: refresh.count }),
    restore() {
      restoreAdc();
      restoreRefresh();
    },
  };
}

function arm(
  target: Record<string, unknown>,
  names: readonly string[],
  bucket: { count: number },
): () => void {
  const originals = new Map<string, unknown>();
  for (const name of names) {
    originals.set(name, target[name]);
    target[name] = () => {
      bucket.count += 1;
      throw new Error(`ambient auth method ${name}`);
    };
  }
  return () => {
    for (const [name, original] of originals) target[name] = original;
  };
}
