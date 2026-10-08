import { Buffer } from 'node:buffer';
import { createHash, createHmac, timingSafeEqual } from 'node:crypto';
import {
  OCR_ACCEPTED_MIME_TYPES,
  OCR_BODY_MAX_BYTES,
  OCR_CLOCK_SKEW_SECONDS,
  OCR_CONTRACT_VERSION,
  OCR_HEADERS,
  OCR_HTTP_METHOD,
  OCR_HTTP_PATH,
  OcrContractError,
  parseOcrPageCount,
  type OcrErrorCode,
} from '../ocr/ocr-contract.ts';

export type RawHeader = readonly [string, string];

export type OcrKey = {
  readonly kid: string;
  readonly secret: Uint8Array;
};

export type OcrKeyRing = {
  readonly environment: string;
  readonly keys: readonly OcrKey[];
};

export type OcrCanonicalFields = {
  environment: string;
  kid: string;
  operationId: string;
  issuedAt: string;
  mime: string;
  contentLength: number;
  pageCount: number;
  timestamp: number;
  nonce: string;
  contentSha256: string;
};

export type SignOcrInput = {
  environment: string;
  kid: string;
  secret: Uint8Array;
  operationId: string;
  issuedAt: string;
  mime: string;
  pageCount: number;
  timestamp: number;
  nonce: string;
  body: Uint8Array;
};

export type OcrSignedRequest = {
  method: string;
  path: string;
  headers: readonly RawHeader[];
  signature: string;
};

export type OcrVerifiedIdentity = {
  ok: true;
  environment: string;
  kid: string;
  operationId: string;
  issuedAt: string;
  mime: string;
  byteLength: number;
  pageCount: number;
  timestamp: number;
  nonce: string;
  digest: string;
};

export type OcrVerification =
  | OcrVerifiedIdentity
  | {
      ok: false;
      code: OcrErrorCode;
    };

export type VerifyOcrInput = {
  ring: OcrKeyRing;
  method: string;
  path: string;
  headers: readonly RawHeader[];
  body: Uint8Array;
  now: Date;
};

export const ENV_PATTERN = /^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$/;
export const KID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;
const OPERATION_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{15,127}$/;
const ISSUED_AT_PATTERN =
  /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d{3})Z$/;
const DECIMAL_PATTERN = /^(0|[1-9][0-9]*)$/;
const TIMESTAMP_PATTERN = /^(0|[1-9][0-9]{0,9})$/;
const NONCE_PATTERN = /^[0-9a-f]{32,64}$/;
const HEX64_PATTERN = /^[0-9a-f]{64}$/;
const MIME_TYPES = new Set<string>(OCR_ACCEPTED_MIME_TYPES);
const SIGNED_HEADER_BY_LOWER = new Map<string, string>(
  Object.values(OCR_HEADERS).map((name) => [name.toLowerCase(), name]),
);

export function canonicalOcrSigningString(fields: OcrCanonicalFields): string {
  const parts = [
    OCR_CONTRACT_VERSION,
    OCR_HTTP_METHOD,
    OCR_HTTP_PATH,
    fields.environment,
    fields.kid,
    fields.operationId,
    fields.issuedAt,
    fields.mime,
    String(fields.contentLength),
    String(fields.pageCount),
    String(fields.timestamp),
    fields.nonce,
    fields.contentSha256,
  ];
  if (parts.some((part) => part.includes('\n') || part.includes('\r'))) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  return `${parts.join('\n')}\n`;
}

const OCR_SECRET_MIN_BYTES = 32;

export function signOcrRequest(input: SignOcrInput): OcrSignedRequest {
  if (input.secret.byteLength < OCR_SECRET_MIN_BYTES) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  if (input.body.byteLength > OCR_BODY_MAX_BYTES) {
    throw new OcrContractError('PAYLOAD_TOO_LARGE');
  }
  if (input.body.byteLength < 1) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  assertGrammar(input);
  const contentSha256 = createHash('sha256').update(input.body).digest('hex');
  const signature = createHmac('sha256', input.secret)
    .update(
      canonicalOcrSigningString({
        environment: input.environment,
        kid: input.kid,
        operationId: input.operationId,
        issuedAt: input.issuedAt,
        mime: input.mime,
        contentLength: input.body.byteLength,
        pageCount: input.pageCount,
        timestamp: input.timestamp,
        nonce: input.nonce,
        contentSha256,
      }),
    )
    .digest('hex');
  return {
    method: OCR_HTTP_METHOD,
    path: OCR_HTTP_PATH,
    signature,
    headers: [
      [OCR_HEADERS.version, OCR_CONTRACT_VERSION],
      [OCR_HEADERS.environment, input.environment],
      [OCR_HEADERS.kid, input.kid],
      [OCR_HEADERS.operationId, input.operationId],
      [OCR_HEADERS.issuedAt, input.issuedAt],
      [OCR_HEADERS.contentType, input.mime],
      [OCR_HEADERS.contentLength, String(input.body.byteLength)],
      [OCR_HEADERS.pageCount, String(input.pageCount)],
      [OCR_HEADERS.timestamp, String(input.timestamp)],
      [OCR_HEADERS.nonce, input.nonce],
      [OCR_HEADERS.contentSha256, contentSha256],
      [OCR_HEADERS.signature, signature],
    ],
  };
}

export function verifyOcrDeclared(
  input: Omit<VerifyOcrInput, 'body'>,
): OcrVerification {
  const collected = collectHeaders(input.headers);
  if (!collected.ok) return collected;
  if (input.method !== OCR_HTTP_METHOD || input.path !== OCR_HTTP_PATH) {
    return { ok: false, code: 'INVALID_CONTRACT' };
  }

  const environment = collected.headers.get(OCR_HEADERS.environment) ?? '';
  const kid = collected.headers.get(OCR_HEADERS.kid) ?? '';
  const operationId = collected.headers.get(OCR_HEADERS.operationId) ?? '';
  const issuedAt = collected.headers.get(OCR_HEADERS.issuedAt) ?? '';
  const mime = collected.headers.get(OCR_HEADERS.contentType) ?? '';
  const lengthText = collected.headers.get(OCR_HEADERS.contentLength) ?? '';
  const pageCountText = collected.headers.get(OCR_HEADERS.pageCount) ?? '';
  const timestampText = collected.headers.get(OCR_HEADERS.timestamp) ?? '';
  const nonce = collected.headers.get(OCR_HEADERS.nonce) ?? '';
  const contentSha256 = collected.headers.get(OCR_HEADERS.contentSha256) ?? '';
  const signature = collected.headers.get(OCR_HEADERS.signature) ?? '';
  const version = collected.headers.get(OCR_HEADERS.version) ?? '';

  if (
    version !== OCR_CONTRACT_VERSION ||
    !ENV_PATTERN.test(environment) ||
    !KID_PATTERN.test(kid) ||
    !OPERATION_PATTERN.test(operationId) ||
    !isCanonicalIssuedAt(issuedAt) ||
    !MIME_TYPES.has(mime) ||
    !DECIMAL_PATTERN.test(lengthText) ||
    !TIMESTAMP_PATTERN.test(timestampText) ||
    !NONCE_PATTERN.test(nonce) ||
    !HEX64_PATTERN.test(contentSha256) ||
    !HEX64_PATTERN.test(signature)
  ) {
    return { ok: false, code: 'INVALID_CONTRACT' };
  }

  const contentLength = Number(lengthText);
  const timestamp = Number(timestampText);
  if (
    contentLength < 1 ||
    contentLength > OCR_BODY_MAX_BYTES ||
    !Number.isSafeInteger(timestamp)
  ) {
    return { ok: false, code: 'INVALID_CONTRACT' };
  }
  let pageCount: number;
  try {
    pageCount = parseOcrPageCount(mime, pageCountText);
  } catch (error) {
    if (error instanceof OcrContractError) {
      return { ok: false, code: 'INVALID_CONTRACT' };
    }
    throw error;
  }
  if (environment !== input.ring.environment) {
    return { ok: false, code: 'FORBIDDEN' };
  }

  const key = findKey(input.ring, kid);
  if (!key || key.secret.byteLength < OCR_SECRET_MIN_BYTES) {
    return { ok: false, code: 'UNAUTHORIZED' };
  }

  const mac = createHmac('sha256', key.secret)
    .update(
      canonicalOcrSigningString({
        environment,
        kid,
        operationId,
        issuedAt,
        mime,
        contentLength,
        pageCount,
        timestamp,
        nonce,
        contentSha256,
      }),
    )
    .digest();
  const presented = Buffer.from(signature, 'hex');
  if (presented.length !== mac.length || !timingSafeEqual(presented, mac)) {
    return { ok: false, code: 'UNAUTHORIZED' };
  }

  const nowMs = input.now.getTime();
  const nowSec = Math.floor(nowMs / 1000);
  if (
    !Number.isFinite(nowMs) ||
    !Number.isSafeInteger(nowSec) ||
    Math.abs(nowSec - timestamp) > OCR_CLOCK_SKEW_SECONDS
  ) {
    return { ok: false, code: 'INVALID_CONTRACT' };
  }
  return {
    ok: true,
    environment,
    kid,
    operationId,
    issuedAt,
    mime,
    byteLength: contentLength,
    pageCount,
    timestamp,
    nonce,
    digest: contentSha256,
  };
}

export function verifyOcrBody(
  declared: OcrVerifiedIdentity,
  body: Uint8Array,
): { ok: true } | { ok: false; code: 'PAYLOAD_TOO_LARGE' | 'UNAUTHORIZED' } {
  if (body.byteLength > OCR_BODY_MAX_BYTES) {
    return { ok: false, code: 'PAYLOAD_TOO_LARGE' };
  }
  if (body.byteLength !== declared.byteLength) {
    return { ok: false, code: 'UNAUTHORIZED' };
  }
  const actual = createHash('sha256').update(body).digest();
  const expected = Buffer.from(declared.digest, 'hex');
  if (expected.length !== actual.length || !timingSafeEqual(expected, actual)) {
    return { ok: false, code: 'UNAUTHORIZED' };
  }
  return { ok: true };
}

export function verifyOcrRequest(input: VerifyOcrInput): OcrVerification {
  const declared = verifyOcrDeclared(input);
  if (!declared.ok) return declared;
  const hashed = verifyOcrBody(declared, input.body);
  if (!hashed.ok) return hashed;
  return declared;
}

function assertGrammar(input: SignOcrInput): void {
  if (
    !ENV_PATTERN.test(input.environment) ||
    !KID_PATTERN.test(input.kid) ||
    !OPERATION_PATTERN.test(input.operationId) ||
    !isCanonicalIssuedAt(input.issuedAt) ||
    !MIME_TYPES.has(input.mime) ||
    !NONCE_PATTERN.test(input.nonce) ||
    !Number.isSafeInteger(input.timestamp) ||
    input.timestamp < 0 ||
    !TIMESTAMP_PATTERN.test(String(input.timestamp))
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  parseOcrPageCount(input.mime, String(input.pageCount));
}

function isCanonicalIssuedAt(value: string): boolean {
  if (!ISSUED_AT_PATTERN.test(value)) return false;
  const parsed = new Date(value);
  return !Number.isNaN(parsed.getTime()) && parsed.toISOString() === value;
}

function collectHeaders(
  headers: readonly RawHeader[],
):
  | { ok: true; headers: Map<string, string> }
  | { ok: false; code: 'INVALID_CONTRACT' } {
  const found = new Map<string, string>();
  for (const [name, value] of headers) {
    const lower = name.toLowerCase();
    if (!lower.startsWith('x-ocr-')) continue;
    const canonical = SIGNED_HEADER_BY_LOWER.get(lower);
    if (!canonical || found.has(canonical)) {
      return { ok: false, code: 'INVALID_CONTRACT' };
    }
    found.set(canonical, value);
  }
  for (const name of SIGNED_HEADER_BY_LOWER.values()) {
    if (!found.has(name)) return { ok: false, code: 'INVALID_CONTRACT' };
  }
  return { ok: true, headers: found };
}

function findKey(ring: OcrKeyRing, kid: string): OcrKey | undefined {
  const matches = ring.keys.filter((key) => key.kid === kid);
  return matches.length === 1 ? matches[0] : undefined;
}
