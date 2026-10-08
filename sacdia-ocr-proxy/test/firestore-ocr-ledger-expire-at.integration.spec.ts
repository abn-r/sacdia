import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { after, before, describe, it } from 'node:test';
import type { Firestore } from '@google-cloud/firestore';
import { createEmulatorFirestore } from '../src/ledger/emulator-target.ts';
import { FirestoreOcrLedger } from '../src/ledger/firestore-ocr-ledger.ts';
import type { AdmitInput } from '../src/ledger/ocr-ledger.port.ts';
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

const requireFirestore = createRequire(import.meta.url);
const { Timestamp, FieldValue } = requireFirestore(
  '@google-cloud/firestore',
) as {
  Timestamp: typeof import('@google-cloud/firestore').Timestamp;
  FieldValue: typeof import('@google-cloud/firestore').FieldValue;
};

const DAY_MS = 24 * 60 * 60 * 1000;
// Calculado de forma independiente del código bajo prueba.
const OPERATION_EXPIRE_AT = new Date(Date.parse(ISSUED_AT) + 8 * DAY_MS);
const NONCE_EXPIRE_AT = new Date(NOW.getTime() + 240_000 + 300_000);
const QUOTA_EXPIRE_AT = new Date(
  Date.parse('2026-10-02T00:00:00.000Z') + DAY_MS + 8 * DAY_MS,
);
const QUOTA_EXPIRE_AT_MINUS_ONE = new Date(QUOTA_EXPIRE_AT.getTime() - 1);
const QUOTA_DAY = '2026-10-02';

type Kind = 'operations' | 'nonces' | 'quota';

describe(
  'ledger Firestore: expireAt (TTL físico) contra el emulador local',
  { concurrency: 1 },
  () => {
    let stop = async () => {};
    let db: Firestore;
    let counter = 0;

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
      await db?.terminate().catch(() => undefined);
      await stop();
    });

    function env(): string {
      counter += 1;
      return `ttl${counter.toString(16).padStart(2, '0')}`;
    }

    function ref(kind: Kind, environment: string, id: string) {
      return db.doc(`ocrLedgers/${environment}/${kind}/${id}`);
    }

    async function expireAtOf(
      kind: Kind,
      environment: string,
      id: string,
    ): Promise<unknown> {
      const snap = await ref(kind, environment, id).get();
      assert.ok(snap.exists, `${kind}/${id} debe existir`);
      return snap.data()?.expireAt;
    }

    function assertTimestampAt(value: unknown, expected: Date): void {
      assert.ok(
        value instanceof Timestamp,
        `expireAt debe ser Timestamp, fue ${typeof value}`,
      );
      assert.equal(value.toMillis(), expected.getTime());
    }

    async function assertAll(
      environment: string,
      operation: string,
      nonce: string,
    ): Promise<void> {
      assertTimestampAt(
        await expireAtOf('operations', environment, operation),
        OPERATION_EXPIRE_AT,
      );
      assertTimestampAt(
        await expireAtOf('nonces', environment, nonce),
        NONCE_EXPIRE_AT,
      );
      assertTimestampAt(
        await expireAtOf('quota', environment, QUOTA_DAY),
        QUOTA_EXPIRE_AT,
      );
    }

    it('admisión guarda expireAt como Timestamp en operación, nonce y cuota', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const admitted = await ledger.admit(admit(environment));
      assert.equal(admitted.status, 'ADMITTED');
      await assertAll(environment, operationId(1), NONCE);

      // Tipo realmente almacenado por el emulador, no solo el que decodifica el SDK.
      for (const [kind, id] of [
        ['operations', operationId(1)],
        ['nonces', NONCE],
        ['quota', QUOTA_DAY],
      ] as const) {
        const response = await fetch(
          `http://${EMULATOR_HOST}:${EMULATOR_PORT}/v1/projects/${EMULATOR_PROJECT}/databases/(default)/documents/ocrLedgers/${environment}/${kind}/${id}`,
          { headers: { authorization: 'Bearer owner' } },
        );
        assert.equal(response.status, 200);
        const body = (await response.json()) as {
          fields: Record<string, Record<string, unknown>>;
        };
        assert.deepEqual(Object.keys(body.fields.expireAt), ['timestampValue']);
        // Las fechas lógicas siguen siendo texto: no se tocaron.
        if (kind === 'operations') {
          assert.ok('stringValue' in body.fields.purgeEligibleAt);
        }
      }
    });

    it('conserva expireAt en CALLING, COMPLETE, UNKNOWN y recover', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const admitted = await ledger.admit(admit(environment));
      assert.equal(admitted.status, 'ADMITTED');
      if (admitted.status !== 'ADMITTED') return;

      const later = new Date(NOW.getTime() + 60_001);
      const recovered = await ledger.recoverPlanned({
        environment,
        operationId: operationId(1),
        now: later,
      });
      assert.equal(recovered.status, 'RECOVERED');
      if (recovered.status !== 'RECOVERED') return;
      await assertAll(environment, operationId(1), NONCE);

      const calling = await ledger.confirmCalling({
        environment,
        operationId: operationId(1),
        fence: recovered.fence,
        now: later,
      });
      assert.equal(calling.status, 'CONFIRMED');
      if (calling.status !== 'CONFIRMED') return;
      assertTimestampAt(
        await expireAtOf('operations', environment, operationId(1)),
        OPERATION_EXPIRE_AT,
      );

      const complete = await ledger.recordComplete({
        environment,
        operationId: operationId(1),
        attemptId: calling.attemptId,
        now: later,
      });
      assert.equal(complete.status, 'RECORDED');
      await assertAll(environment, operationId(1), NONCE);

      const other = env();
      await ledger.admit(admit(other));
      const started = await ledger.confirmCalling({
        environment: other,
        operationId: operationId(1),
        fence: 1,
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
      await assertAll(other, operationId(1), NONCE);
    });

    it('cubre nonces de rutas EXPIRED, CONFLICT, QUOTA y ALREADY_RESERVED', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      await ledger.admit(admit(environment, { limit: 1 }));
      const results = [
        await ledger.admit(
          admit(environment, { limit: 1, nonce: nonceFor(2) }),
        ),
        await ledger.admit(
          admit(environment, {
            limit: 1,
            nonce: nonceFor(3),
            digest: OTHER_DIGEST,
          }),
        ),
        await ledger.admit(
          admit(environment, {
            limit: 1,
            nonce: nonceFor(4),
            operationId: operationId(2),
          }),
        ),
        await ledger.admit(
          admit(environment, {
            limit: 1,
            nonce: nonceFor(5),
            operationId: operationId(3),
            issuedAt: new Date(NOW.getTime() - 8 * DAY_MS).toISOString(),
          }),
        ),
      ];
      assert.deepEqual(
        results.map((r) => r.status),
        ['ALREADY_RESERVED', 'CONFLICT', 'QUOTA', 'EXPIRED'],
      );
      for (const index of [2, 3, 4, 5]) {
        assertTimestampAt(
          await expireAtOf('nonces', environment, nonceFor(index)),
          NONCE_EXPIRE_AT,
        );
      }
    });

    it('una reescritura nunca adelanta expireAt (cuota con fecha lógica posterior)', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      await ledger.admit(admit(environment));
      const later = new Date(QUOTA_EXPIRE_AT.getTime() + 30 * DAY_MS);
      await ref('quota', environment, QUOTA_DAY).update({
        purgeEligibleAt: later.toISOString(),
      });
      const second = await ledger.admit(
        admit(environment, {
          operationId: operationId(2),
          nonce: nonceFor(2),
        }),
      );
      assert.equal(second.status, 'ADMITTED');
      assertTimestampAt(
        await expireAtOf('quota', environment, QUOTA_DAY),
        later,
      );
      const third = await ledger.admit(
        admit(environment, {
          operationId: operationId(3),
          nonce: nonceFor(3),
        }),
      );
      assert.equal(third.status, 'ADMITTED');
      assertTimestampAt(
        await expireAtOf('quota', environment, QUOTA_DAY),
        later,
      );
    });

    it('expireAt de cada documento es monótono a lo largo de todas las reescrituras', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const seen: number[] = [];
      const sample = async () => {
        const op = (await expireAtOf(
          'operations',
          environment,
          operationId(1),
        )) as InstanceType<typeof Timestamp>;
        const quota = (await expireAtOf(
          'quota',
          environment,
          QUOTA_DAY,
        )) as InstanceType<typeof Timestamp>;
        seen.push(op.toMillis(), quota.toMillis());
      };
      await ledger.admit(admit(environment));
      await sample();
      await ledger.admit(
        admit(environment, {
          operationId: operationId(2),
          nonce: nonceFor(2),
        }),
      );
      await sample();
      await ledger.recoverPlanned({
        environment,
        operationId: operationId(1),
        now: new Date(NOW.getTime() + 60_001),
      });
      await sample();
      const calling = await ledger.confirmCalling({
        environment,
        operationId: operationId(1),
        fence: 2,
        now: new Date(NOW.getTime() + 60_001),
      });
      await sample();
      if (calling.status === 'CONFIRMED') {
        await ledger.recordComplete({
          environment,
          operationId: operationId(1),
          attemptId: calling.attemptId,
          now: new Date(NOW.getTime() + 60_001),
        });
      }
      await sample();
      const ops = seen.filter((_, index) => index % 2 === 0);
      const quotas = seen.filter((_, index) => index % 2 === 1);
      for (const series of [ops, quotas]) {
        for (let index = 1; index < series.length; index += 1) {
          assert.ok(series[index] >= series[index - 1], 'expireAt retrocedió');
        }
        assert.equal(new Set(series).size, 1);
      }
    });

    it('las tres colecciones tienen expireAt tras CADA transición, con varias admisiones el mismo día', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const nonces: string[] = [];
      const operations: string[] = [];
      const checkAll = async () => {
        for (const id of operations) {
          assertTimestampAt(
            await expireAtOf('operations', environment, id),
            OPERATION_EXPIRE_AT,
          );
        }
        for (const id of nonces) {
          assertTimestampAt(
            await expireAtOf('nonces', environment, id),
            NONCE_EXPIRE_AT,
          );
        }
        assertTimestampAt(
          await expireAtOf('quota', environment, QUOTA_DAY),
          QUOTA_EXPIRE_AT,
        );
      };
      for (let index = 1; index <= 3; index += 1) {
        operations.push(operationId(index));
        nonces.push(nonceFor(index));
        const admitted = await ledger.admit(
          admit(environment, {
            operationId: operationId(index),
            nonce: nonceFor(index),
          }),
        );
        assert.equal(admitted.status, 'ADMITTED');
        await checkAll();
      }
      const later = new Date(NOW.getTime() + 60_001);
      const recovered = await ledger.recoverPlanned({
        environment,
        operationId: operationId(1),
        now: later,
      });
      assert.equal(recovered.status, 'RECOVERED');
      await checkAll();
      const calling = await ledger.confirmCalling({
        environment,
        operationId: operationId(1),
        fence: 2,
        now: later,
      });
      assert.equal(calling.status, 'CONFIRMED');
      await checkAll();
      if (calling.status !== 'CONFIRMED') return;
      assert.equal(
        (
          await ledger.recordComplete({
            environment,
            operationId: operationId(1),
            attemptId: calling.attemptId,
            now: later,
          })
        ).status,
        'RECORDED',
      );
      await checkAll();
      const second = await ledger.confirmCalling({
        environment,
        operationId: operationId(2),
        fence: 1,
        now: later,
      });
      assert.equal(second.status, 'CONFIRMED');
      if (second.status !== 'CONFIRMED') return;
      await ledger.recordUnknown({
        environment,
        operationId: operationId(2),
        attemptId: second.attemptId,
        now: later,
      });
      await checkAll();
      // Reintentos y rechazos que reescriben nonces o cuota no los acortan.
      await ledger.admit(admit(environment, { nonce: nonceFor(10) }));
      nonces.push(nonceFor(10));
      await checkAll();
    });

    it('cuota con purgeEligibleAt no textual: expireAt sigue el valor escrito y no baja', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      await ledger.admit(admit(environment));
      await ref('quota', environment, QUOTA_DAY).update({
        purgeEligibleAt: 2030,
      });
      const second = await ledger.admit(
        admit(environment, {
          operationId: operationId(2),
          nonce: nonceFor(2),
        }),
      );
      assert.equal(second.status, 'ADMITTED');
      const quota = (await ref('quota', environment, QUOTA_DAY).get()).data();
      assert.equal(quota?.purgeEligibleAt, QUOTA_EXPIRE_AT.toISOString());
      assertTimestampAt(quota?.expireAt, QUOTA_EXPIRE_AT);
    });

    it('documentos legados sin expireAt reciben el campo al reescribirse', async () => {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      await ledger.admit(admit(environment));
      await ref('operations', environment, operationId(1)).update({
        expireAt: FieldValue.delete(),
      });
      await ref('quota', environment, QUOTA_DAY).update({
        expireAt: FieldValue.delete(),
      });
      const calling = await ledger.confirmCalling({
        environment,
        operationId: operationId(1),
        fence: 1,
        now: NOW,
      });
      assert.equal(calling.status, 'CONFIRMED');
      const second = await ledger.admit(
        admit(environment, {
          operationId: operationId(2),
          nonce: nonceFor(2),
        }),
      );
      assert.equal(second.status, 'ADMITTED');
      await assertAll(environment, operationId(1), NONCE);
      assertTimestampAt(
        await expireAtOf('operations', environment, operationId(2)),
        OPERATION_EXPIRE_AT,
      );
    });

    const BASE_TRACE = [
      'ADMITTED:1',
      'ALREADY_RESERVED:1',
      'REPLAY',
      'CONFLICT',
      'EXPIRED',
      'EXPIRED',
      'RECOVERED:2',
      'CONFIRMED:2',
      'RECORDED',
      'purge(nonces antes de retener)=0',
      'purge(nonces a los 9 min)=6',
      'purge(operación 8d-1)=0',
      'purge(operación 8d)=1',
      'purge(cuota antes)=0',
      'purge(cuota 9d)=1',
    ];

    for (const mode of [
      'none',
      'past',
      'future',
      'absent',
      'string',
    ] as const) {
      it(`la lógica no lee expireAt (${mode}): mismo resultado que el control`, async () => {
        const trace = await runScenario(mode);
        assert.deepEqual(trace, BASE_TRACE);
      });
    }

    async function runScenario(
      mode: 'none' | 'past' | 'future' | 'absent' | 'string',
    ): Promise<string[]> {
      const ledger = new FirestoreOcrLedger(db);
      const environment = env();
      const trace: string[] = [];
      const nonces = [NONCE, ...[2, 3, 4, 5, 6].map(nonceFor)];
      const tamper = async () => {
        if (mode === 'none') return;
        const value =
          mode === 'past'
            ? Timestamp.fromMillis(0)
            : mode === 'future'
              ? Timestamp.fromMillis(Date.parse('2100-01-01T00:00:00.000Z'))
              : mode === 'absent'
                ? FieldValue.delete()
                : '1999-01-01T00:00:00.000Z';
        const targets = [
          ref('operations', environment, operationId(1)),
          ref('quota', environment, QUOTA_DAY),
          ...nonces.map((nonce) => ref('nonces', environment, nonce)),
        ];
        for (const target of targets) {
          if ((await target.get()).exists) {
            await target.update({ expireAt: value });
          }
        }
      };
      const input = admit(environment);
      const stamp = (result: { status: string; fence?: number }) =>
        result.fence === undefined
          ? result.status
          : `${result.status}:${result.fence}`;

      await tamper();
      trace.push(stamp(await ledger.admit(input)));
      await tamper();
      trace.push(stamp(await ledger.admit({ ...input, nonce: nonceFor(2) })));
      await tamper();
      trace.push(
        stamp(
          await ledger.admit({
            ...input,
            operationId: operationId(2),
            nonce: NONCE,
          }),
        ),
      );
      await tamper();
      trace.push(
        stamp(
          await ledger.admit({
            ...input,
            digest: OTHER_DIGEST,
            nonce: nonceFor(3),
          }),
        ),
      );
      await tamper();
      trace.push(
        stamp(
          await ledger.admit({
            ...input,
            operationId: operationId(3),
            nonce: nonceFor(4),
            issuedAt: new Date(NOW.getTime() - 8 * DAY_MS).toISOString(),
          }),
        ),
      );
      await tamper();
      trace.push(
        stamp(
          await ledger.admit({
            ...input,
            nonce: nonceFor(5),
            now: new Date(NOW.getTime() + 7 * DAY_MS + 1),
          }),
        ),
      );
      await tamper();
      const recovered = await ledger.recoverPlanned({
        environment,
        operationId: operationId(1),
        now: new Date(NOW.getTime() + 60_001),
      });
      trace.push(stamp(recovered));
      await tamper();
      const calling = await ledger.confirmCalling({
        environment,
        operationId: operationId(1),
        fence: recovered.status === 'RECOVERED' ? recovered.fence : 0,
        now: new Date(NOW.getTime() + 60_001),
      });
      trace.push(stamp(calling));
      await tamper();
      const recorded = await ledger.recordComplete({
        environment,
        operationId: operationId(1),
        attemptId: calling.status === 'CONFIRMED' ? calling.attemptId : '',
        now: new Date(NOW.getTime() + 60_001),
      });
      trace.push(stamp(recorded));
      // Nonce 6 para completar los seis documentos de nonce del control.
      await ledger.admit({
        ...input,
        operationId: operationId(4),
        nonce: nonceFor(6),
        issuedAt: new Date(NOW.getTime() - 8 * DAY_MS).toISOString(),
      });
      await tamper();

      const purge = async (
        label: string,
        now: Date,
        over: { operations?: string[]; nonces?: string[]; quota?: string[] },
      ) => {
        await tamper();
        const result = await ledger.purgeIfEligible({
          environment,
          now,
          operationIds: over.operations ?? [],
          nonces: over.nonces ?? [],
          quotaDays: over.quota ?? [],
        });
        trace.push(`purge(${label})=${result.deleted}`);
      };
      await purge(
        'nonces antes de retener',
        new Date(NOW.getTime() + 539_999),
        {
          nonces,
        },
      );
      await purge('nonces a los 9 min', new Date(NOW.getTime() + 540_000), {
        nonces,
      });
      await purge('operación 8d-1', new Date(NOW.getTime() + 8 * DAY_MS - 1), {
        operations: [operationId(1)],
      });
      await purge('operación 8d', new Date(NOW.getTime() + 8 * DAY_MS), {
        operations: [operationId(1)],
      });
      await purge('cuota antes', QUOTA_EXPIRE_AT_MINUS_ONE, {
        quota: [QUOTA_DAY],
      });
      await purge('cuota 9d', QUOTA_EXPIRE_AT, { quota: [QUOTA_DAY] });
      return trace;
    }
  },
);

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
