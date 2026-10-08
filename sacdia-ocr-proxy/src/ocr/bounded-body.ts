import { Buffer } from 'node:buffer';
import {
  OCR_BODY_MAX_BYTES,
  OCR_BODY_READ_TIMEOUT_MS,
  OcrContractError,
  assertBinaryTransport,
} from './ocr-contract.ts';

export type BoundedBodyOptions = {
  contentType?: string | null;
  contentEncoding?: string | null;
  contentLength?: number | null;
  maxBytes?: number;
  timeoutMs?: number;
};

export async function readBoundedBody(
  source: AsyncIterable<Uint8Array>,
  options: BoundedBodyOptions = {},
): Promise<Buffer> {
  assertBinaryTransport({
    contentType: options.contentType,
    contentEncoding: options.contentEncoding,
  });
  if (
    options.contentLength != null &&
    (!Number.isInteger(options.contentLength) || options.contentLength < 0)
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  const maxBytes = options.maxBytes ?? OCR_BODY_MAX_BYTES;
  if (
    !Number.isInteger(maxBytes) ||
    maxBytes < 1 ||
    maxBytes > OCR_BODY_MAX_BYTES
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }

  const timeoutMs = options.timeoutMs ?? OCR_BODY_READ_TIMEOUT_MS;
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs < 1) {
    throw new OcrContractError('INVALID_CONTRACT');
  }

  const iterator = source[Symbol.asyncIterator]();
  const chunks: Buffer[] = [];
  let total = 0;
  let rejectTimeout: ((error: Error) => void) | undefined;
  const timeout = new Promise<never>((_, reject) => {
    rejectTimeout = reject;
  });
  const timer = setTimeout(() => {
    rejectTimeout?.(new Error('body-read-timeout'));
  }, timeoutMs);
  try {
    while (true) {
      const pending = iterator.next();
      void pending.then(
        () => undefined,
        () => undefined,
      );
      const next = await Promise.race([pending, timeout]);
      if (next.done) break;
      const chunk = next.value;
      if (total + chunk.byteLength > maxBytes) {
        throw new OcrContractError('PAYLOAD_TOO_LARGE');
      }
      const bytes = Buffer.from(chunk);
      total += bytes.byteLength;
      chunks.push(bytes);
    }
  } catch (error) {
    if (error instanceof OcrContractError) throw error;
    throw new OcrContractError('DISCONNECTED');
  } finally {
    clearTimeout(timer);
  }
  return Buffer.concat(chunks);
}
