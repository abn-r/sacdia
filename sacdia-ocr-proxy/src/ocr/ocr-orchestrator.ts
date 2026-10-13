import { Buffer } from 'node:buffer';
import { randomBytes as nodeRandomBytes } from 'node:crypto';
import {
  verifyOcrRequest,
  type OcrKeyRing,
  type OcrVerifiedIdentity,
  type RawHeader,
} from '../auth/ocr-signature.ts';
import type {
  AdmitResult,
  ConfirmCallingResult,
  OcrLedger,
  RecordResult,
  RecoverResult,
} from '../ledger/ocr-ledger.port.ts';
import type {
  VisionReadResult,
  VisionTextReader,
} from '../vision/vision-text-reader.ts';
import { admitOperation } from './ocr-admission.ts';
import {
  OCR_ERROR_HTTP,
  OCR_HEADERS,
  OCR_HTTP_METHOD,
  OCR_HTTP_PATH,
  OcrContractError,
  serializeOcrError,
  serializeOcrSuccess,
  type OcrErrorCode,
} from './ocr-contract.ts';
import {
  DeadlineExpired,
  defaultOcrSleep,
  remainingDeadlineMs,
  waitBounded,
  type DeadlineSleep,
  type MonotonicClock,
} from './ocr-deadline.ts';
import { magicMatchesMime } from './magic-bytes.ts';

export type OcrMetrics = {
  requests: number;
  visionCalls: number;
  failures: number;
};

export type OcrRuntime = {
  ring: OcrKeyRing;
  ledger: OcrLedger;
  reader: VisionTextReader;
  pageLimit?: unknown;
  now?: () => Date;
  hrtime?: MonotonicClock;
  sleep?: DeadlineSleep;
  log?: (event: string, code: string) => void;
  metrics?: OcrMetrics;
  randomBytes?: (size: number) => Uint8Array;
};

export type OcrHttpResult = {
  status: number;
  body: Buffer;
};

type KnownIds = {
  operationId?: string;
  nonce?: string;
  digest?: string;
};

export async function handleOcrRequest(
  request: {
    method: string;
    path: string;
    headers: readonly RawHeader[];
    body: Uint8Array;
  },
  runtime: OcrRuntime,
): Promise<OcrHttpResult> {
  if (request.method === 'GET' && request.path === '/ready') {
    return {
      status: 200,
      body: Buffer.from('{"version":"v1","ready":true}'),
    };
  }
  const known = knownIds(request.headers);
  if (request.method !== OCR_HTTP_METHOD || request.path !== OCR_HTTP_PATH) {
    return failure(runtime, 'INVALID_CONTRACT', known);
  }
  if (runtime.metrics) runtime.metrics.requests += 1;
  const now = runtime.now ?? (() => new Date());
  const receivedAt = now();
  const verified = verifyOcrRequest({
    ring: runtime.ring,
    method: request.method,
    path: request.path,
    headers: request.headers,
    body: request.body,
    now: receivedAt,
  });
  if (!verified.ok) return failure(runtime, verified.code, known);
  const identity = verified;
  const signed: KnownIds = {
    operationId: identity.operationId,
    nonce: identity.nonce,
    digest: identity.digest,
  };
  if (!magicMatchesMime(identity.mime, request.body)) {
    return failure(
      runtime,
      identity.mime === 'application/pdf' ? 'PDF_INVALID' : 'UNSUPPORTED_TYPE',
      signed,
    );
  }

  const clock = runtime.hrtime ?? (() => process.hrtime.bigint());
  const sleep = runtime.sleep ?? defaultOcrSleep;
  const origin = clock();
  const remaining = () => remainingDeadlineMs(origin, clock);

  let admitted: AdmitResult;
  const admitBudget = remaining();
  if (admitBudget <= 0) return failure(runtime, 'UNAVAILABLE', signed);
  try {
    admitted = await waitBounded(
      admitOperation(runtime.ledger, runtime.pageLimit, identity, {
        receivedAt,
        now: receivedAt,
      }),
      admitBudget,
      sleep,
    );
  } catch (error) {
    if (error instanceof DeadlineExpired) {
      return failure(runtime, 'UNAVAILABLE', signed);
    }
    return failure(runtime, 'UNAVAILABLE', signed);
  }
  if (admitted.status === 'ALREADY_RESERVED') {
    const recoverBudget = remaining();
    if (recoverBudget <= 0) return failure(runtime, 'UNAVAILABLE', signed);
    try {
      const recovered = await waitBounded(
        runtime.ledger.recoverPlanned({
          environment: identity.environment,
          operationId: identity.operationId,
          now: now(),
        }),
        recoverBudget,
        sleep,
      );
      if (recovered.status !== 'RECOVERED') {
        return failure(runtime, recoverError(recovered.status), signed);
      }
      admitted = { status: 'ADMITTED', fence: recovered.fence };
    } catch {
      return failure(runtime, 'UNAVAILABLE', signed);
    }
  } else if (admitted.status !== 'ADMITTED') {
    return failure(runtime, admitError(admitted.status), signed);
  }

  let confirmed: ConfirmCallingResult;
  const confirmBudget = remaining();
  if (confirmBudget <= 0) return failure(runtime, 'UNAVAILABLE', signed);
  try {
    confirmed = await waitBounded(
      runtime.ledger.confirmCalling({
        environment: identity.environment,
        operationId: identity.operationId,
        fence: admitted.fence,
        now: now(),
      }),
      confirmBudget,
      sleep,
    );
  } catch {
    return failure(runtime, 'UNAVAILABLE', signed);
  }
  if (confirmed.status !== 'CONFIRMED') {
    return failure(runtime, confirmError(confirmed.status), signed);
  }
  const attemptId = confirmed.attemptId;

  const readBudget = remaining();
  if (readBudget <= 0) {
    await settleUnknown(runtime, identity, attemptId, now, remaining, sleep);
    return failure(runtime, 'UNCERTAIN', signed);
  }
  if (runtime.metrics) runtime.metrics.visionCalls += 1;
  let read: VisionReadResult;
  try {
    read = await waitBounded(
      runtime.reader.read({
        mime: identity.mime,
        content: request.body,
        pageCount: identity.pageCount,
        remainingMs: readBudget,
      }),
      readBudget,
      sleep,
    );
  } catch {
    await settleUnknown(runtime, identity, attemptId, now, remaining, sleep);
    return failure(runtime, 'UNCERTAIN', signed);
  }

  const invalid = responseCode(read, identity.pageCount);
  if (invalid) {
    await settleUnknown(runtime, identity, attemptId, now, remaining, sleep);
    return failure(runtime, invalid, signed);
  }

  let success: Buffer;
  try {
    success = serializeOcrSuccess({
      operationId: identity.operationId,
      pageCount: identity.pageCount,
      pages: read.pages.map((page) => ({
        pageNumber: page.pageNumber ?? 0,
        text: page.text,
      })),
    });
  } catch (error) {
    const code = error instanceof OcrContractError ? error.code : 'UNCERTAIN';
    await settleUnknown(runtime, identity, attemptId, now, remaining, sleep);
    return failure(runtime, code, signed);
  }

  let recorded: RecordResult;
  const recordBudget = remaining();
  if (recordBudget <= 0) {
    await settleUnknown(runtime, identity, attemptId, now, remaining, sleep);
    return failure(runtime, 'UNCERTAIN', signed);
  }
  try {
    recorded = await waitBounded(
      runtime.ledger.recordComplete({
        environment: identity.environment,
        operationId: identity.operationId,
        attemptId,
        now: now(),
      }),
      recordBudget,
      sleep,
    );
  } catch {
    await settleUnknown(runtime, identity, attemptId, now, remaining, sleep);
    return failure(runtime, 'UNCERTAIN', signed);
  }
  if (recorded.status !== 'RECORDED') {
    await settleUnknown(runtime, identity, attemptId, now, remaining, sleep);
    return failure(runtime, 'UNCERTAIN', signed);
  }
  runtime.log?.('ocr_ok', 'OK');
  return { status: 200, body: success };
}

async function settleUnknown(
  runtime: OcrRuntime,
  identity: OcrVerifiedIdentity,
  attemptId: string,
  now: () => Date,
  remaining: () => number,
  sleep: DeadlineSleep,
): Promise<void> {
  const budget = remaining();
  if (budget <= 0) return;
  try {
    await waitBounded(
      runtime.ledger.recordUnknown({
        environment: identity.environment,
        operationId: identity.operationId,
        attemptId,
        now: now(),
      }),
      budget,
      sleep,
    );
  } catch {
    return;
  }
}

function responseCode(
  read: VisionReadResult,
  pageCount: number,
): OcrErrorCode | null {
  if (read.fileErrorCode != null && read.fileErrorCode !== 0) {
    return 'UNCERTAIN';
  }
  if (
    read.pages.some((page) => page.errorCode != null && page.errorCode !== 0)
  ) {
    return 'UNCERTAIN';
  }
  if (read.totalPages != null && read.totalPages !== pageCount) {
    return 'PAGE_COUNT_MISMATCH';
  }
  if (read.pages.length !== pageCount) return 'UNCERTAIN';
  for (let index = 0; index < pageCount; index += 1) {
    if (read.pages[index]?.pageNumber !== index + 1) return 'UNCERTAIN';
  }
  return null;
}

function recoverError(
  status: Exclude<RecoverResult['status'], 'RECOVERED'>,
): OcrErrorCode {
  switch (status) {
    case 'NOT_RECOVERABLE':
      return 'CONFLICT';
    case 'UNCERTAIN':
      return 'UNCERTAIN';
    case 'INVALID_CONTRACT':
      return 'INVALID_CONTRACT';
    case 'UNAVAILABLE':
      return 'UNAVAILABLE';
    default:
      return 'UNAVAILABLE';
  }
}

function admitError(
  status: Exclude<AdmitResult['status'], 'ADMITTED'>,
): OcrErrorCode {
  switch (status) {
    case 'ALREADY_RESERVED':
    case 'CONFLICT':
      return 'CONFLICT';
    case 'REPLAY':
      return 'UNAUTHORIZED';
    case 'QUOTA':
      return 'QUOTA';
    case 'EXPIRED':
    case 'INVALID_CONTRACT':
      return 'INVALID_CONTRACT';
    case 'UNAVAILABLE':
      return 'UNAVAILABLE';
    default:
      return 'UNAVAILABLE';
  }
}

function confirmError(
  status: Exclude<ConfirmCallingResult['status'], 'CONFIRMED'>,
): OcrErrorCode {
  switch (status) {
    case 'LOST_FENCE':
      return 'CONFLICT';
    case 'EXPIRED':
    case 'INVALID_CONTRACT':
      return 'INVALID_CONTRACT';
    case 'UNCERTAIN':
      return 'UNCERTAIN';
    case 'UNAVAILABLE':
      return 'UNAVAILABLE';
    default:
      return 'UNAVAILABLE';
  }
}

export function ocrErrorResult(
  runtime: OcrRuntime,
  code: OcrErrorCode,
  headers: readonly RawHeader[] = [],
): OcrHttpResult {
  return failure(runtime, code, knownIds(headers));
}

function failure(
  runtime: OcrRuntime,
  code: OcrErrorCode,
  known: KnownIds,
): OcrHttpResult {
  if (runtime.metrics) runtime.metrics.failures += 1;
  runtime.log?.('ocr_error', code);
  const requestId = requestIdFor(known, runtime.randomBytes ?? nodeRandomBytes);
  return {
    status: OCR_ERROR_HTTP[code],
    body: serializeOcrError({
      code,
      requestId,
      operationId: known.operationId,
      nonce: known.nonce,
      contentSha256: known.digest,
    }),
  };
}

function requestIdFor(
  known: KnownIds,
  random: (size: number) => Uint8Array,
): string {
  const banned = new Set(
    [known.operationId, known.nonce, known.digest].filter(
      (value): value is string => typeof value === 'string',
    ),
  );
  for (let attempt = 0; attempt < 4; attempt += 1) {
    const requestId = Buffer.from(random(16)).toString('hex');
    if (/^[0-9a-f]{32}$/.test(requestId) && !banned.has(requestId)) {
      return requestId;
    }
  }
  for (const filler of [0x11, 0x22, 0x33]) {
    const requestId = Buffer.alloc(16, filler).toString('hex');
    if (!banned.has(requestId)) return requestId;
  }
  return 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
}

function knownIds(headers: readonly RawHeader[]): KnownIds {
  return {
    operationId: headerValue(headers, OCR_HEADERS.operationId),
    nonce: headerValue(headers, OCR_HEADERS.nonce),
    digest: headerValue(headers, OCR_HEADERS.contentSha256),
  };
}

function headerValue(
  headers: readonly RawHeader[],
  name: string,
): string | undefined {
  let found: string | undefined;
  const expected = name.toLowerCase();
  for (const [key, value] of headers) {
    if (key.toLowerCase() !== expected) continue;
    if (found !== undefined) return undefined;
    found = value;
  }
  return found;
}
