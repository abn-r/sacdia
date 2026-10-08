import assert from 'node:assert/strict';
import { createHash, createHmac } from 'node:crypto';
import { Buffer } from 'node:buffer';
import { describe, it } from 'node:test';
import {
  verifyOcrRequest,
  type OcrVerification,
} from '../src/auth/ocr-signature.ts';
import { OCR_HEADERS } from '../src/ocr/ocr-contract.ts';
import {
  admitOperation,
  callAfterDurableCalling,
} from '../src/ocr/ocr-admission.ts';
import type {
  AdmitInput,
  AdmitResult,
  OcrLedger,
} from '../src/ledger/ocr-ledger.port.ts';
import {
  DIGEST,
  ISSUED_AT,
  NONCE,
  NOW,
  nonceFor,
  operationId,
} from './support/ledger-sample.ts';

describe('admisión sin probar atomicidad de Firestore', () => {
  it('no abre la cuota cuando el límite es inválido', async () => {
    let calls = 0;
    const ledger = {
      async admit(): Promise<AdmitResult> {
        calls += 1;
        return { status: 'ADMITTED', fence: 1 };
      },
    } as unknown as OcrLedger;
    for (const limit of [
      0,
      -1,
      1.5,
      401,
      Number.NaN,
      Number.POSITIVE_INFINITY,
      '400',
    ]) {
      const result = await admitOperation(
        ledger,
        limit,
        verifiedIdentity(),
        sample(),
      );
      assert.equal(result.status, 'INVALID_CONTRACT');
    }
    const open = await admitOperation(
      ledger,
      undefined,
      verifiedIdentity(),
      sample(),
    );
    assert.equal(open.status, 'ADMITTED');
    assert.equal(calls, 1);
  });

  it('ejecuta el efecto solo después de un CALLING confirmado', async () => {
    const order: string[] = [];
    const called = await callAfterDurableCalling(
      async () => {
        order.push('confirm');
        return { status: 'CONFIRMED', fence: 2, attemptId: 'attempt-1' };
      },
      () => order.push('effect'),
    );
    assert.equal(called, 'CALLED');
    assert.deepEqual(order, ['confirm', 'effect']);

    let effects = 0;
    const skipped = await callAfterDurableCalling(
      async () => ({ status: 'UNCERTAIN' }),
      () => {
        effects += 1;
      },
    );
    assert.equal(skipped, 'NOT_CALLED');
    assert.equal(effects, 0);
  });

  it('no admite si el resultado verificado no trae pageCount', async () => {
    let calls = 0;
    const ledger = {
      async admit(): Promise<AdmitResult> {
        calls += 1;
        return { status: 'ADMITTED', fence: 1 };
      },
    } as unknown as OcrLedger;
    const result = await admitOperation(
      ledger,
      400,
      { ok: true } as OcrVerification,
      sample(),
    );
    assert.equal(result.status, 'INVALID_CONTRACT');
    assert.equal(calls, 0);
  });

  it('reserva el pageCount firmado y otro conteo del mismo operationId es CONFLICT', async () => {
    const seen: AdmitInput[] = [];
    const ledger = {
      async admit(input: AdmitInput): Promise<AdmitResult> {
        const previous = seen.find(
          (item) => item.operationId === input.operationId,
        );
        seen.push(input);
        if (previous && previous.pageCount !== input.pageCount) {
          return { status: 'CONFLICT' };
        }
        return { status: 'ADMITTED', fence: seen.length };
      },
    } as unknown as OcrLedger;
    const first = verifySigned('5', 'application/pdf');
    assert.equal(first.ok, true);
    if (!first.ok) return;
    const admitted = await admitOperation(
      ledger,
      400,
      first,
      withDecoyPageCount('application/pdf', 1),
    );
    assert.equal(admitted.status, 'ADMITTED');
    assert.equal(seen[0]?.pageCount, 5);
    assert.equal(seen[0]?.mime, 'application/pdf');
    assert.equal(seen[0]?.operationId, operationId(1));

    const second = verifySigned('3', 'application/pdf', nonceFor(2));
    assert.equal(second.ok, true);
    if (!second.ok) return;
    const conflict = await admitOperation(
      ledger,
      400,
      second,
      withDecoyPageCount('application/pdf', 1, nonceFor(2)),
    );
    assert.equal(conflict.status, 'CONFLICT');
    assert.equal(seen[1]?.pageCount, 3);
    assert.equal(callsOf(seen), 2);
  });

  it('admite solo la identidad firmada, no un digest o MIME sustituto', async () => {
    const seen: AdmitInput[] = [];
    const ledger = {
      async admit(input: AdmitInput): Promise<AdmitResult> {
        seen.push(input);
        return { status: 'ADMITTED', fence: 1 };
      },
    } as unknown as OcrLedger;
    const verified = verifySigned('1', 'image/jpeg');
    assert.equal(verified.ok, true);
    if (!verified.ok) return;
    assert.equal(verified.environment, 'development');
    assert.equal(verified.kid, 'k-current');
    assert.equal(verified.operationId, operationId(1));
    assert.equal(verified.issuedAt, ISSUED_AT);
    assert.equal(verified.mime, 'image/jpeg');
    assert.equal(verified.byteLength, 21);
    assert.equal(verified.pageCount, 1);
    assert.equal(verified.timestamp, 1_759_420_000);
    assert.equal(verified.nonce, NONCE);
    assert.equal(verified.digest, DIGEST);
    const substituted = {
      receivedAt: NOW,
      now: NOW,
      environment: 'other-env',
      digest: 'ab'.repeat(32),
      mime: 'application/pdf',
      operationId: operationId(9),
      byteLength: 99,
      nonce: nonceFor(9),
    };
    const admitted = await admitOperation(ledger, 400, verified, substituted);
    assert.equal(admitted.status, 'ADMITTED');
    assert.equal(seen[0]?.environment, 'development');
    assert.equal(seen[0]?.digest, DIGEST);
    assert.equal(seen[0]?.mime, 'image/jpeg');
    assert.equal(seen[0]?.operationId, operationId(1));
    assert.equal(seen[0]?.byteLength, 21);
    assert.equal(seen[0]?.nonce, NONCE);
    assert.equal(seen[0]?.issuedAt, ISSUED_AT);
    assert.equal(seen[0]?.requestTimestamp, 1_759_420_000);
    assert.equal(seen[0]?.pageCount, 1);
  });
});

function withDecoyPageCount(
  mime: string,
  pageCount: number,
  nonce = NONCE,
): Omit<AdmitInput, 'limit'> {
  return {
    ...sample(),
    mime,
    nonce,
    pageCount,
  };
}

function verifiedIdentity(): OcrVerification {
  return {
    ok: true,
    environment: 'development',
    kid: 'k-current',
    operationId: operationId(1),
    issuedAt: ISSUED_AT,
    mime: 'image/jpeg',
    byteLength: 21,
    pageCount: 1,
    timestamp: 1_759_420_000,
    nonce: NONCE,
    digest: DIGEST,
  };
}

function sample() {
  return {
    environment: 'development',
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
  };
}

const ADMIT_SECRET = Buffer.from('0123456789abcdef0123456789abcdef');
const ADMIT_BODY = Buffer.from('synthetic certificate');

function verifySigned(pageCountText: string, mime: string, nonce = NONCE) {
  const contentSha256 = createHash('sha256').update(ADMIT_BODY).digest('hex');
  const signature = createHmac('sha256', ADMIT_SECRET)
    .update(
      [
        'v1',
        'POST',
        '/v1/ocr',
        'development',
        'k-current',
        operationId(1),
        ISSUED_AT,
        mime,
        String(ADMIT_BODY.length),
        pageCountText,
        '1759420000',
        nonce,
        contentSha256,
      ].join('\n') + '\n',
    )
    .digest('hex');
  return verifyOcrRequest({
    ring: {
      environment: 'development',
      keys: [{ kid: 'k-current', secret: ADMIT_SECRET }],
    },
    method: 'POST',
    path: '/v1/ocr',
    headers: [
      [OCR_HEADERS.version, 'v1'],
      [OCR_HEADERS.environment, 'development'],
      [OCR_HEADERS.kid, 'k-current'],
      [OCR_HEADERS.operationId, operationId(1)],
      [OCR_HEADERS.issuedAt, ISSUED_AT],
      [OCR_HEADERS.contentType, mime],
      [OCR_HEADERS.contentLength, String(ADMIT_BODY.length)],
      ['X-Ocr-Page-Count', pageCountText],
      [OCR_HEADERS.timestamp, '1759420000'],
      [OCR_HEADERS.nonce, nonce],
      [OCR_HEADERS.contentSha256, contentSha256],
      [OCR_HEADERS.signature, signature],
    ],
    body: ADMIT_BODY,
    now: new Date(1_759_420_000 * 1000),
  });
}

function callsOf(seen: readonly unknown[]): number {
  return seen.length;
}
