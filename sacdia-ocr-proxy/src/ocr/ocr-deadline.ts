export const OCR_DEADLINE_MS = 35_000;

export type MonotonicClock = () => bigint;
export type DeadlineSleep = (ms: number, signal: AbortSignal) => Promise<void>;

export class DeadlineExpired extends Error {
  constructor() {
    super('DEADLINE');
    this.name = 'DeadlineExpired';
  }
}

export function defaultOcrSleep(
  ms: number,
  signal: AbortSignal,
): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal.aborted) {
      reject(new Error('aborted'));
      return;
    }
    const onAbort = () => {
      clearTimeout(timer);
      reject(new Error('aborted'));
    };
    const timer = setTimeout(() => {
      signal.removeEventListener('abort', onAbort);
      resolve();
    }, ms);
    signal.addEventListener('abort', onAbort, { once: true });
  });
}

export function remainingDeadlineMs(
  origin: bigint,
  clock: MonotonicClock,
  budgetMs = OCR_DEADLINE_MS,
): number {
  const elapsed = clock() - origin;
  if (elapsed <= 0n) return budgetMs;
  const elapsedMs = Number(elapsed / 1_000_000n);
  if (!Number.isFinite(elapsedMs)) return 0;
  return budgetMs - elapsedMs;
}

export async function waitBounded<T>(
  operation: Promise<T>,
  budgetMs: number,
  sleep: DeadlineSleep,
): Promise<T> {
  if (!Number.isFinite(budgetMs) || budgetMs <= 0) {
    throw new DeadlineExpired();
  }
  const abort = new AbortController();
  const timeout = sleep(budgetMs, abort.signal).then(
    () => 'EXPIRED' as const,
    () => 'EXPIRED' as const,
  );
  try {
    const winner = await Promise.race([
      operation.then(
        (value) => ({ kind: 'value' as const, value }),
        (error: unknown) => ({ kind: 'error' as const, error }),
      ),
      timeout.then(() => ({ kind: 'expired' as const })),
    ]);
    if (winner.kind === 'expired') throw new DeadlineExpired();
    if (winner.kind === 'error') throw winner.error;
    return winner.value;
  } finally {
    abort.abort();
  }
}
