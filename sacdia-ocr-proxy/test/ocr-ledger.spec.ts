import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { OcrContractError } from '../src/ocr/ocr-contract.ts';
import {
  LEDGER_GUARANTEE_SCOPE,
  NONCE_LOGICAL_WINDOW_MS,
  NONCE_RETAIN_AFTER_LOGICAL_EXPIRY_MS,
  isOperationExpired,
  isPurgeEligible,
  nonceSchedule,
  operationSchedule,
  utcDay,
} from '../src/ledger/ocr-ledger-time.ts';
import {
  InertEmulatorAuth,
  createEmulatorFirestore,
} from '../src/ledger/emulator-target.ts';
import { NOW } from './support/ledger-sample.ts';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');

describe('tiempos del ledger local', () => {
  it('retiene el nonce cinco minutos después del vencimiento lógico', () => {
    const schedule = nonceSchedule(NOW);
    assert.equal(
      schedule.logicalExpiresAt.getTime() - NOW.getTime(),
      NONCE_LOGICAL_WINDOW_MS,
    );
    assert.equal(NONCE_LOGICAL_WINDOW_MS, 240_000);
    assert.equal(
      schedule.retainUntil.getTime() - schedule.logicalExpiresAt.getTime(),
      NONCE_RETAIN_AFTER_LOGICAL_EXPIRY_MS,
    );
    assert.equal(NONCE_RETAIN_AFTER_LOGICAL_EXPIRY_MS, 300_000);
    assert.equal(
      isPurgeEligible(
        schedule.retainUntil,
        new Date(schedule.retainUntil.getTime() - 1),
      ),
      false,
    );
    assert.equal(
      isPurgeEligible(schedule.retainUntil, schedule.retainUntil),
      true,
    );
  });

  it('vence la operación a los siete días y la hace purgable a los ocho', () => {
    const schedule = operationSchedule(NOW);
    const day = 24 * 60 * 60 * 1000;
    assert.equal(schedule.logicalExpiresAt.getTime() - NOW.getTime(), 7 * day);
    assert.equal(schedule.purgeEligibleAt.getTime() - NOW.getTime(), 8 * day);
    assert.equal(isOperationExpired(NOW, schedule.logicalExpiresAt), false);
    assert.equal(
      isOperationExpired(
        NOW,
        new Date(schedule.logicalExpiresAt.getTime() + 1),
      ),
      true,
    );
    assert.equal(
      isPurgeEligible(
        schedule.purgeEligibleAt,
        new Date(schedule.purgeEligibleAt.getTime() - 1),
      ),
      false,
    );
  });

  it('rechaza un reloj inválido al calcular plazos', () => {
    assert.throws(
      () => nonceSchedule(new Date(Number.NaN)),
      (error: unknown) =>
        error instanceof OcrContractError && error.code === 'INVALID_CONTRACT',
    );
  });

  it('identifica el día UTC de la cuota', () => {
    assert.equal(utcDay(new Date('2026-10-02T23:30:00.000Z')), '2026-10-02');
    assert.equal(utcDay(new Date('2026-10-03T00:00:00.000Z')), '2026-10-03');
  });

  it('describe la garantía como local y no exactly-once de producción', () => {
    assert.match(LEDGER_GUARANTEE_SCOPE, /local/);
    assert.doesNotMatch(LEDGER_GUARANTEE_SCOPE, /production exactly-once/i);
  });
});

describe('cliente del emulador', () => {
  it('valida loopback y proyecto demo antes de crear el cliente', () => {
    let connects = 0;
    const connect = () => {
      connects += 1;
      throw new Error('should not connect');
    };
    assert.throws(
      () =>
        createEmulatorFirestore(
          {
            FIRESTORE_EMULATOR_HOST: 'firestore.googleapis.com:443',
            GCLOUD_PROJECT: 'demo-ocr-local',
          },
          connect,
        ),
      (error: unknown) => error instanceof OcrContractError,
    );
    assert.throws(
      () =>
        createEmulatorFirestore(
          {
            FIRESTORE_EMULATOR_HOST: '127.0.0.1:8099',
            GCLOUD_PROJECT: 'prod-ocr',
          },
          connect,
        ),
      (error: unknown) => error instanceof OcrContractError,
    );
    assert.throws(
      () =>
        createEmulatorFirestore(
          {
            FIRESTORE_EMULATOR_HOST: '127.0.0.1:8099',
            GCLOUD_PROJECT: 'demo-ocr-local',
            GOOGLE_APPLICATION_CREDENTIALS: '/tmp/adc.json',
          },
          connect,
        ),
      (error: unknown) => error instanceof OcrContractError,
    );
    assert.equal(connects, 0);
  });

  it('configura el proceso y no pasa credenciales al conector', async () => {
    const previousHost = process.env.FIRESTORE_EMULATOR_HOST;
    const previousProject = process.env.GCLOUD_PROJECT;
    let settings: Record<string, unknown> | undefined;
    createEmulatorFirestore(
      {
        FIRESTORE_EMULATOR_HOST: '127.0.0.1:8099',
        GCLOUD_PROJECT: 'demo-ocr-local',
      },
      (input) => {
        settings = input as unknown as Record<string, unknown>;
        return { connected: true } as never;
      },
    );
    assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8099');
    assert.equal(process.env.GCLOUD_PROJECT, 'demo-ocr-local');
    assert.equal(settings?.host, '127.0.0.1');
    assert.equal(settings?.port, 8099);
    assert.equal(settings?.projectId, 'demo-ocr-local');
    assert.equal(settings?.ssl, false);
    assert.equal(settings?.keyFilename, undefined);
    assert.equal(settings?.credentials, undefined);
    assert.ok(settings?.auth instanceof InertEmulatorAuth);
    assert.equal(settings?.auth, settings?.authClient);
    const headers = (settings?.auth as InertEmulatorAuth).getRequestHeaders();
    assert.equal(headers.get('authorization'), 'Bearer owner');
    await assert.rejects(
      () =>
        (settings?.auth as InertEmulatorAuth).fetch(
          'https://oauth2.googleapis.com/token',
        ),
      (error: unknown) => error instanceof OcrContractError,
    );
    if (previousHost === undefined) delete process.env.FIRESTORE_EMULATOR_HOST;
    else process.env.FIRESTORE_EMULATOR_HOST = previousHost;
    if (previousProject === undefined) delete process.env.GCLOUD_PROJECT;
    else process.env.GCLOUD_PROJECT = previousProject;
  });

  it('no declara consultas compuestas en el adaptador', () => {
    const source = readFileSync(
      path.join(ROOT, 'src/ledger/firestore-ocr-ledger.ts'),
      'utf8',
    );
    assert.equal(source.includes('.where('), false);
    assert.equal(source.includes('.orderBy('), false);
  });
});
