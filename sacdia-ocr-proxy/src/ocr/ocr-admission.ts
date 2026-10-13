import type {
  OcrVerification,
  OcrVerifiedIdentity,
} from '../auth/ocr-signature.ts';
import type {
  AdmitInput,
  AdmitResult,
  OcrLedger,
} from '../ledger/ocr-ledger.port.ts';
import {
  OCR_PAGE_COUNT_MAX,
  OcrContractError,
  resolveDailyPageLimit,
} from './ocr-contract.ts';

export type AdmitTiming = {
  receivedAt: Date;
  now: Date;
  leaseMs?: number;
};

export async function admitOperation(
  ledger: OcrLedger,
  rawLimit: unknown,
  verified: OcrVerification,
  timing: AdmitTiming,
): Promise<AdmitResult> {
  if (!isVerifiedIdentity(verified)) return { status: 'INVALID_CONTRACT' };
  let limit: number;
  try {
    limit = resolveDailyPageLimit(rawLimit);
  } catch (error) {
    if (
      error instanceof OcrContractError &&
      error.code === 'INVALID_CONTRACT'
    ) {
      return { status: 'INVALID_CONTRACT' };
    }
    throw error;
  }
  const input: AdmitInput = {
    environment: verified.environment,
    operationId: verified.operationId,
    issuedAt: verified.issuedAt,
    digest: verified.digest,
    mime: verified.mime,
    byteLength: verified.byteLength,
    pageCount: verified.pageCount,
    nonce: verified.nonce,
    requestTimestamp: verified.timestamp,
    receivedAt: timing.receivedAt,
    now: timing.now,
    limit,
  };
  if (timing.leaseMs !== undefined) input.leaseMs = timing.leaseMs;
  return ledger.admit(input);
}

function isVerifiedIdentity(
  verified: OcrVerification,
): verified is OcrVerifiedIdentity {
  if (!verified.ok) return false;
  return (
    typeof verified.environment === 'string' &&
    typeof verified.kid === 'string' &&
    typeof verified.operationId === 'string' &&
    typeof verified.issuedAt === 'string' &&
    typeof verified.mime === 'string' &&
    Number.isInteger(verified.byteLength) &&
    verified.byteLength >= 1 &&
    Number.isInteger(verified.pageCount) &&
    verified.pageCount >= 1 &&
    verified.pageCount <= OCR_PAGE_COUNT_MAX &&
    Number.isInteger(verified.timestamp) &&
    verified.timestamp >= 0 &&
    typeof verified.nonce === 'string' &&
    typeof verified.digest === 'string'
  );
}

export async function callAfterDurableCalling(
  confirm: () => Promise<{ status: string }>,
  effect: () => void,
): Promise<'CALLED' | 'NOT_CALLED'> {
  const result = await confirm();
  if (result.status !== 'CONFIRMED') return 'NOT_CALLED';
  effect();
  return 'CALLED';
}
