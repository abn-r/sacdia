import { OcrContractError } from '../ocr/ocr-contract.ts';

export const NONCE_LOGICAL_WINDOW_MS = 240_000;
export const NONCE_RETAIN_AFTER_LOGICAL_EXPIRY_MS = 300_000;
export const OPERATION_LOGICAL_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;
export const OPERATION_PURGE_WINDOW_MS = 8 * 24 * 60 * 60 * 1000;

export const LEDGER_GUARANTEE_SCOPE =
  'local emulator integration only; production durability and delivery guarantees stay unverified';

export function nonceSchedule(receivedAt: Date): {
  logicalExpiresAt: Date;
  retainUntil: Date;
} {
  requireFiniteDate(receivedAt);
  const logicalExpiresAt = new Date(
    receivedAt.getTime() + NONCE_LOGICAL_WINDOW_MS,
  );
  return {
    logicalExpiresAt,
    retainUntil: new Date(
      logicalExpiresAt.getTime() + NONCE_RETAIN_AFTER_LOGICAL_EXPIRY_MS,
    ),
  };
}

export function operationSchedule(issuedAt: Date): {
  logicalExpiresAt: Date;
  purgeEligibleAt: Date;
} {
  requireFiniteDate(issuedAt);
  return {
    logicalExpiresAt: new Date(
      issuedAt.getTime() + OPERATION_LOGICAL_WINDOW_MS,
    ),
    purgeEligibleAt: new Date(issuedAt.getTime() + OPERATION_PURGE_WINDOW_MS),
  };
}

export function isOperationExpired(issuedAt: Date, now: Date): boolean {
  requireFiniteDate(issuedAt);
  requireFiniteDate(now);
  return now.getTime() > operationSchedule(issuedAt).logicalExpiresAt.getTime();
}

export function isPurgeEligible(threshold: Date, now: Date): boolean {
  requireFiniteDate(threshold);
  requireFiniteDate(now);
  return now.getTime() >= threshold.getTime();
}

export function utcDay(value: Date): string {
  requireFiniteDate(value);
  return value.toISOString().slice(0, 10);
}

export function quotaPurgeEligibleAt(day: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  const start = new Date(`${day}T00:00:00.000Z`);
  if (
    Number.isNaN(start.getTime()) ||
    start.toISOString().slice(0, 10) !== day
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  return new Date(
    start.getTime() + 24 * 60 * 60 * 1000 + OPERATION_PURGE_WINDOW_MS,
  );
}

function requireFiniteDate(value: Date): void {
  if (!(value instanceof Date) || !Number.isFinite(value.getTime())) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
}
