import { Buffer } from 'node:buffer';

export const OCR_CONTRACT_VERSION = 'v1';
export const OCR_HTTP_METHOD = 'POST';
export const OCR_HTTP_PATH = '/v1/ocr';
export const OCR_BODY_MAX_BYTES = 10_485_760;
export const OCR_HEADERS_TIMEOUT_MS = 10_000;
export const OCR_BODY_READ_TIMEOUT_MS = 10_000;
export const OCR_REQUEST_TIMEOUT_MS = 35_000;
export const OCR_HTTP_TIMEOUT_CHECK_MS = 1_000;
export const OCR_RESPONSE_MAX_BYTES = 16_777_216;
export const OCR_CLOCK_SKEW_SECONDS = 120;
export const OCR_DAILY_PAGE_LIMIT_DEFAULT = 400;
export const OCR_DAILY_PAGE_LIMIT_MAX = 400;
export const OCR_MAX_PAGES_PER_ENV_PER_DAY = 'OCR_MAX_PAGES_PER_ENV_PER_DAY';
export const OCR_PAGE_COUNT_MAX = 5;

const PAGE_COUNT_TEXT = /^[1-5]$/;
const IMAGE_MIME_TYPES = new Set<string>([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

export function parseOcrPageCount(mime: string, value: string): number {
  if (!PAGE_COUNT_TEXT.test(value)) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  const pageCount = Number(value);
  if (mime === 'application/pdf') return pageCount;
  if (IMAGE_MIME_TYPES.has(mime) && pageCount === 1) return pageCount;
  throw new OcrContractError('INVALID_CONTRACT');
}

export const OCR_ACCEPTED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
] as const;

export type OcrMimeType = (typeof OCR_ACCEPTED_MIME_TYPES)[number];

export const OCR_HEADERS = {
  version: 'X-Ocr-Version',
  environment: 'X-Ocr-Env',
  kid: 'X-Ocr-Kid',
  operationId: 'X-Ocr-Operation-Id',
  issuedAt: 'X-Ocr-Issued-At',
  contentType: 'X-Ocr-Content-Type',
  contentLength: 'X-Ocr-Content-Length',
  pageCount: 'X-Ocr-Page-Count',
  timestamp: 'X-Ocr-Timestamp',
  nonce: 'X-Ocr-Nonce',
  contentSha256: 'X-Ocr-Content-SHA256',
  signature: 'X-Ocr-Signature',
} as const;

export const OCR_ERROR_CODES = [
  'UNAUTHORIZED',
  'FORBIDDEN',
  'INVALID_CONTRACT',
  'UNSUPPORTED_TYPE',
  'PAYLOAD_TOO_LARGE',
  'PDF_TOO_MANY_PAGES',
  'PDF_ENCRYPTED',
  'PDF_INVALID',
  'EMPTY_DOCUMENT',
  'RESPONSE_TOO_LARGE',
  'CONFLICT',
  'QUOTA',
  'UNAVAILABLE',
  'DISCONNECTED',
  'ENCODED',
  'UNCERTAIN',
  'PAGE_COUNT_MISMATCH',
] as const;

export type OcrErrorCode = (typeof OCR_ERROR_CODES)[number];

export const OCR_ERROR_HTTP: Record<OcrErrorCode, number> = {
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  INVALID_CONTRACT: 400,
  UNSUPPORTED_TYPE: 400,
  PAYLOAD_TOO_LARGE: 413,
  PDF_TOO_MANY_PAGES: 400,
  PDF_ENCRYPTED: 400,
  PDF_INVALID: 400,
  EMPTY_DOCUMENT: 400,
  RESPONSE_TOO_LARGE: 504,
  CONFLICT: 409,
  QUOTA: 429,
  UNAVAILABLE: 503,
  DISCONNECTED: 503,
  ENCODED: 400,
  UNCERTAIN: 504,
  PAGE_COUNT_MISMATCH: 502,
};

export const OCR_RENDER_ERROR: Record<OcrErrorCode, string> = {
  UNAUTHORIZED: 'CERTIFICATE_IMPORT_OCR_UNAVAILABLE',
  FORBIDDEN: 'CERTIFICATE_IMPORT_OCR_UNAVAILABLE',
  INVALID_CONTRACT: 'CERTIFICATE_IMPORT_OCR_FAILED',
  UNSUPPORTED_TYPE: 'CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE',
  PAYLOAD_TOO_LARGE: 'CERTIFICATE_IMPORT_OCR_FILE_TOO_LARGE',
  PDF_TOO_MANY_PAGES: 'CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES',
  PDF_ENCRYPTED: 'CERTIFICATE_IMPORT_PDF_ENCRYPTED',
  PDF_INVALID: 'CERTIFICATE_IMPORT_PDF_INVALID',
  EMPTY_DOCUMENT: 'CERTIFICATE_IMPORT_OCR_FAILED',
  RESPONSE_TOO_LARGE: 'CERTIFICATE_IMPORT_OCR_FAILED',
  CONFLICT: 'CERTIFICATE_IMPORT_OCR_FAILED',
  QUOTA: 'CERTIFICATE_IMPORT_OCR_QUOTA',
  UNAVAILABLE: 'CERTIFICATE_IMPORT_OCR_UNAVAILABLE',
  DISCONNECTED: 'CERTIFICATE_IMPORT_OCR_UNAVAILABLE',
  ENCODED: 'CERTIFICATE_IMPORT_OCR_FAILED',
  UNCERTAIN: 'CERTIFICATE_IMPORT_OCR_FAILED',
  PAGE_COUNT_MISMATCH: 'CERTIFICATE_IMPORT_OCR_FAILED',
};

const FILE_ID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const OPERATION_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{15,127}$/;
const REQUEST_ID_PATTERN = /^[0-9a-f]{32}$/;
const REDIRECT_STATUSES = new Set([301, 302, 303, 307, 308]);
const ERROR_CODE_SET = new Set<string>(OCR_ERROR_CODES);

export class OcrContractError extends Error {
  readonly code: OcrErrorCode;

  constructor(code: OcrErrorCode) {
    super(code);
    this.name = 'OcrContractError';
    this.code = code;
  }
}

export type OcrPage = {
  pageNumber: number;
  text: string;
};

export type OcrSuccessInput = {
  operationId: string;
  pageCount: number;
  pages: readonly OcrPage[];
};

export type OcrErrorInput = {
  code: OcrErrorCode;
  requestId: string;
  operationId?: string;
  nonce?: string;
  contentSha256?: string;
};

export type OcrOperationSource = {
  fileId: string;
  confirmedAt: Date | null;
};

export function resolveDailyPageLimit(value: unknown): number {
  if (value === undefined) return OCR_DAILY_PAGE_LIMIT_DEFAULT;
  if (
    typeof value !== 'number' ||
    !Number.isInteger(value) ||
    value < 1 ||
    value > OCR_DAILY_PAGE_LIMIT_MAX
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  return value;
}

export function deriveOcrOperation(file: OcrOperationSource): {
  operationId: string;
  issuedAt: string;
} {
  if (!FILE_ID_PATTERN.test(file.fileId)) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  if (
    !(file.confirmedAt instanceof Date) ||
    Number.isNaN(file.confirmedAt.getTime())
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  return {
    operationId: file.fileId,
    issuedAt: file.confirmedAt.toISOString(),
  };
}

export function assertNoRedirect(status: number): void {
  if (REDIRECT_STATUSES.has(status)) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
}

export function assertBinaryTransport(input: {
  contentType?: string | null;
  contentEncoding?: string | null;
}): void {
  const encoding = input.contentEncoding;
  if (encoding != null && encoding !== '' && encoding !== 'identity') {
    throw new OcrContractError('ENCODED');
  }
  const contentType = input.contentType;
  if (
    contentType != null &&
    contentType !== '' &&
    contentType !== 'application/octet-stream'
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
}

export function serializeOcrSuccess(input: OcrSuccessInput): Buffer {
  if (!OPERATION_ID_PATTERN.test(input.operationId)) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  if (
    !Number.isInteger(input.pageCount) ||
    input.pageCount < 1 ||
    input.pageCount > OCR_PAGE_COUNT_MAX
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  if (input.pages.length !== input.pageCount) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  const seen = new Set<number>();
  for (const page of input.pages) {
    if (!isExactPage(page) || seen.has(page.pageNumber)) {
      throw new OcrContractError('INVALID_CONTRACT');
    }
    if (page.pageNumber < 1 || page.pageNumber > input.pageCount) {
      throw new OcrContractError('INVALID_CONTRACT');
    }
    seen.add(page.pageNumber);
  }
  if (seen.size !== input.pageCount) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  const ordered = [...input.pages].sort(
    (left, right) => left.pageNumber - right.pageNumber,
  );
  if (ordered.every((page) => page.text.trim() === '')) {
    throw new OcrContractError('EMPTY_DOCUMENT');
  }
  const json = JSON.stringify({
    version: OCR_CONTRACT_VERSION,
    operationId: input.operationId,
    pageCount: input.pageCount,
    pages: ordered.map((page) => ({
      pageNumber: page.pageNumber,
      text: page.text,
    })),
  });
  const bytes = Buffer.from(json, 'utf8');
  if (bytes.byteLength > OCR_RESPONSE_MAX_BYTES) {
    throw new OcrContractError('RESPONSE_TOO_LARGE');
  }
  return bytes;
}

export function serializeOcrError(input: OcrErrorInput): Buffer {
  if (
    !ERROR_CODE_SET.has(input.code) ||
    !REQUEST_ID_PATTERN.test(input.requestId)
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  if (
    input.operationId === input.requestId ||
    input.nonce === input.requestId ||
    input.contentSha256 === input.requestId
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  return Buffer.from(
    JSON.stringify({
      version: OCR_CONTRACT_VERSION,
      code: input.code,
      requestId: input.requestId,
    }),
    'utf8',
  );
}

function isExactPage(page: OcrPage): boolean {
  if (page === null || typeof page !== 'object') return false;
  const keys = Object.keys(page);
  return (
    keys.length === 2 &&
    keys.includes('pageNumber') &&
    keys.includes('text') &&
    Number.isInteger(page.pageNumber) &&
    typeof page.text === 'string'
  );
}
