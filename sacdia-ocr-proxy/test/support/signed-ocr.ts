import { createHash, createHmac } from 'node:crypto';
import { Buffer } from 'node:buffer';
import type { RawHeader } from '../../src/auth/ocr-signature.ts';
import { OCR_HEADERS } from '../../src/ocr/ocr-contract.ts';
import { ISSUED_AT, nonceFor, operationId } from './ledger-sample.ts';

export const OCR_SECRET = Buffer.from('0123456789abcdef0123456789abcdef');
export const SIGN_TIMESTAMP = 1_759_420_000;
export const SIGN_NOW = new Date(SIGN_TIMESTAMP * 1000);
export const OCR_MARKER = 'OCR-PRIVATE-MARKER';

export type SignedOcr = {
  headers: RawHeader[];
  body: Buffer;
  digest: string;
  environment: string;
  operationId: string;
  nonce: string;
  mime: string;
  pageCount: number;
};

export function jpegBytes(): Buffer {
  return Buffer.from([0xff, 0xd8, 0xff, 0xd9]);
}

export function pngBytes(): Buffer {
  return Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
}

export function webpBytes(): Buffer {
  return Buffer.concat([
    Buffer.from('RIFF'),
    Buffer.alloc(4),
    Buffer.from('WEBP'),
  ]);
}

export function pdfBytes(): Buffer {
  return Buffer.from('%PDF-1.7\n');
}

export function signOcrBytes(input: {
  body: Buffer;
  mime: string;
  pageCount: number;
  environment?: string;
  operationId?: string;
  nonce?: string;
  issuedAt?: string;
}): SignedOcr {
  const environment = input.environment ?? 'development';
  const operation = input.operationId ?? operationId(1);
  const nonce = input.nonce ?? nonceFor(1);
  const issuedAt = input.issuedAt ?? ISSUED_AT;
  const digest = createHash('sha256').update(input.body).digest('hex');
  const signature = createHmac('sha256', OCR_SECRET)
    .update(
      [
        'v1',
        'POST',
        '/v1/ocr',
        environment,
        'k-current',
        operation,
        issuedAt,
        input.mime,
        String(input.body.length),
        String(input.pageCount),
        String(SIGN_TIMESTAMP),
        nonce,
        digest,
      ].join('\n') + '\n',
    )
    .digest('hex');
  return {
    headers: [
      [OCR_HEADERS.version, 'v1'],
      [OCR_HEADERS.environment, environment],
      [OCR_HEADERS.kid, 'k-current'],
      [OCR_HEADERS.operationId, operation],
      [OCR_HEADERS.issuedAt, issuedAt],
      [OCR_HEADERS.contentType, input.mime],
      [OCR_HEADERS.contentLength, String(input.body.length)],
      [OCR_HEADERS.pageCount, String(input.pageCount)],
      [OCR_HEADERS.timestamp, String(SIGN_TIMESTAMP)],
      [OCR_HEADERS.nonce, nonce],
      [OCR_HEADERS.contentSha256, digest],
      [OCR_HEADERS.signature, signature],
    ],
    body: input.body,
    digest,
    environment,
    operationId: operation,
    nonce,
    mime: input.mime,
    pageCount: input.pageCount,
  };
}
