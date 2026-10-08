import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { Buffer } from 'node:buffer';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';
import {
  OCR_BODY_MAX_BYTES,
  OCR_ERROR_CODES,
  OCR_ERROR_HTTP,
  OCR_HEADERS,
  OCR_MAX_PAGES_PER_ENV_PER_DAY,
  OCR_RENDER_ERROR,
  OCR_RESPONSE_MAX_BYTES,
  OcrContractError,
  assertBinaryTransport,
  assertNoRedirect,
  deriveOcrOperation,
  resolveDailyPageLimit,
  serializeOcrError,
  serializeOcrSuccess,
} from '../src/ocr/ocr-contract.ts';
import { readBoundedBody } from '../src/ocr/bounded-body.ts';

const FILE_ID = '11111111-1111-4111-8111-111111111111';
const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const RENDER_CODES = new Set([
  'CERTIFICATE_IMPORT_OCR_UNAVAILABLE',
  'CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE',
  'CERTIFICATE_IMPORT_OCR_FILE_TOO_LARGE',
  'CERTIFICATE_IMPORT_OCR_FAILED',
  'CERTIFICATE_IMPORT_OCR_QUOTA',
  'CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES',
  'CERTIFICATE_IMPORT_PDF_ENCRYPTED',
  'CERTIFICATE_IMPORT_PDF_INVALID',
]);
const HTTP_CODES = new Set([400, 401, 403, 409, 413, 429, 502, 503, 504]);

function isContractError(error: unknown, code: string): boolean {
  return error instanceof OcrContractError && error.code === code;
}

async function* chunksOf(parts: Buffer[]): AsyncGenerator<Buffer> {
  for (const part of parts) yield part;
}

describe('contrato OCR v1', () => {
  it('nombra el conteo firmado X-Ocr-Page-Count', () => {
    assert.equal(OCR_HEADERS.pageCount, 'X-Ocr-Page-Count');
  });

  it('fija los topes binarios y el nombre de la cuota diaria', () => {
    assert.equal(OCR_BODY_MAX_BYTES, 10_485_760);
    assert.equal(OCR_RESPONSE_MAX_BYTES, 16_777_216);
    assert.equal(
      OCR_MAX_PAGES_PER_ENV_PER_DAY,
      'OCR_MAX_PAGES_PER_ENV_PER_DAY',
    );
  });

  it('mapea cada código interno a un HTTP aprobado y a un código Render existente', () => {
    assert.equal(OCR_ERROR_HTTP.UNAUTHORIZED, 401);
    assert.equal(OCR_ERROR_HTTP.FORBIDDEN, 403);
    assert.equal(OCR_ERROR_HTTP.PAYLOAD_TOO_LARGE, 413);
    assert.equal(OCR_ERROR_HTTP.QUOTA, 429);
    assert.equal(OCR_ERROR_HTTP.UNAVAILABLE, 503);
    assert.equal(OCR_ERROR_HTTP.DISCONNECTED, 503);
    assert.equal(OCR_ERROR_HTTP.CONFLICT, 409);
    assert.equal(OCR_ERROR_HTTP.RESPONSE_TOO_LARGE, 504);
    assert.equal(OCR_ERROR_HTTP.UNCERTAIN, 504);
    assert.equal(OCR_ERROR_HTTP.PDF_TOO_MANY_PAGES, 400);
    assert.equal(
      OCR_RENDER_ERROR.UNAUTHORIZED,
      'CERTIFICATE_IMPORT_OCR_UNAVAILABLE',
    );
    assert.equal(
      OCR_RENDER_ERROR.FORBIDDEN,
      'CERTIFICATE_IMPORT_OCR_UNAVAILABLE',
    );
    assert.equal(
      OCR_RENDER_ERROR.UNSUPPORTED_TYPE,
      'CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE',
    );
    assert.equal(
      OCR_RENDER_ERROR.PAYLOAD_TOO_LARGE,
      'CERTIFICATE_IMPORT_OCR_FILE_TOO_LARGE',
    );
    assert.equal(
      OCR_RENDER_ERROR.PDF_TOO_MANY_PAGES,
      'CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES',
    );
    assert.equal(
      OCR_RENDER_ERROR.PDF_ENCRYPTED,
      'CERTIFICATE_IMPORT_PDF_ENCRYPTED',
    );
    assert.equal(
      OCR_RENDER_ERROR.PDF_INVALID,
      'CERTIFICATE_IMPORT_PDF_INVALID',
    );
    assert.equal(OCR_RENDER_ERROR.QUOTA, 'CERTIFICATE_IMPORT_OCR_QUOTA');
    assert.equal(OCR_RENDER_ERROR.CONFLICT, 'CERTIFICATE_IMPORT_OCR_FAILED');
    assert.equal(
      OCR_RENDER_ERROR.EMPTY_DOCUMENT,
      'CERTIFICATE_IMPORT_OCR_FAILED',
    );
    assert.equal(
      OCR_RENDER_ERROR.RESPONSE_TOO_LARGE,
      'CERTIFICATE_IMPORT_OCR_FAILED',
    );
    assert.equal(OCR_RENDER_ERROR.UNCERTAIN, 'CERTIFICATE_IMPORT_OCR_FAILED');
    assert.equal(OCR_ERROR_HTTP.PAGE_COUNT_MISMATCH, 502);
    assert.equal(
      OCR_RENDER_ERROR.PAGE_COUNT_MISMATCH,
      'CERTIFICATE_IMPORT_OCR_FAILED',
    );
    for (const code of OCR_ERROR_CODES) {
      assert.equal(HTTP_CODES.has(OCR_ERROR_HTTP[code]), true, code);
      assert.equal(RENDER_CODES.has(OCR_RENDER_ERROR[code]), true, code);
    }
  });

  it('usa 400 páginas cuando la cuota falta y rechaza cero, negativos y el exceso', () => {
    assert.equal(resolveDailyPageLimit(undefined), 400);
    assert.equal(resolveDailyPageLimit(400), 400);
    assert.equal(resolveDailyPageLimit(1), 1);
    for (const value of [
      0,
      -1,
      401,
      1.5,
      Number.NaN,
      Number.POSITIVE_INFINITY,
      '400',
      null,
    ]) {
      assert.throws(
        () => resolveDailyPageLimit(value),
        (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
      );
    }
  });

  it('deriva operationId e issuedAt del archivo sellado, sin reloj ni usuario', () => {
    const confirmedAt = new Date('2026-10-02T15:04:05.006Z');
    const first = deriveOcrOperation({ fileId: FILE_ID, confirmedAt });
    const second = deriveOcrOperation({
      fileId: FILE_ID,
      confirmedAt,
      userId: 'user-1',
    } as { fileId: string; confirmedAt: Date });
    assert.deepEqual(first, second);
    assert.equal(first.operationId, FILE_ID);
    assert.equal(first.issuedAt, '2026-10-02T15:04:05.006Z');
    assert.equal(JSON.stringify(first).includes('user-1'), false);
    const other = deriveOcrOperation({
      fileId: '22222222-2222-4222-8222-222222222222',
      confirmedAt,
    });
    assert.notEqual(other.operationId, first.operationId);
    assert.equal(
      deriveOcrOperation({
        fileId: FILE_ID,
        confirmedAt: new Date(Date.UTC(2026, 9, 2, 15, 4, 5, 6)),
      }).issuedAt,
      '2026-10-02T15:04:05.006Z',
    );
  });

  it('falla cerrado si el archivo no tiene fecha de sello o el id no es canónico', () => {
    const confirmedAt = new Date('2026-10-02T15:04:05.006Z');
    const withLetters = 'abcdefab-abcd-4abc-8abc-abcdefabcdef';
    assert.equal(
      deriveOcrOperation({ fileId: withLetters, confirmedAt }).operationId,
      withLetters,
    );
    assert.throws(
      () => deriveOcrOperation({ fileId: FILE_ID, confirmedAt: null }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        deriveOcrOperation({
          fileId: withLetters.toUpperCase(),
          confirmedAt,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () => deriveOcrOperation({ fileId: FILE_ID, confirmedAt: new Date(NaN) }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });

  it('rechaza redirects y no descomprime el transporte', () => {
    assert.doesNotThrow(() => assertNoRedirect(200));
    for (const status of [301, 302, 303, 307, 308]) {
      assert.throws(
        () => assertNoRedirect(status),
        (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
      );
    }
    assert.doesNotThrow(() =>
      assertBinaryTransport({
        contentType: 'application/octet-stream',
        contentEncoding: 'identity',
      }),
    );
    assert.doesNotThrow(() => assertBinaryTransport({}));
    assert.throws(
      () => assertBinaryTransport({ contentEncoding: 'gzip' }),
      (error: unknown) => isContractError(error, 'ENCODED'),
    );
    assert.throws(
      () => assertBinaryTransport({ contentType: 'image/jpeg' }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });
});

describe('lectura acotada', () => {
  it('acepta 10 MiB exactos, un byte extra y un cuerpo en chunks', async () => {
    const exact = Buffer.alloc(OCR_BODY_MAX_BYTES, 7);
    const read = await readBoundedBody(
      chunksOf([exact.subarray(0, 3), exact.subarray(3)]),
    );
    assert.equal(read.length, OCR_BODY_MAX_BYTES);
    assert.equal(read.equals(exact), true);
    await assert.rejects(
      readBoundedBody(chunksOf([exact, Buffer.from([1])])),
      (error: unknown) => isContractError(error, 'PAYLOAD_TOO_LARGE'),
    );
  });

  it('conserva los bytes aunque el productor reutilice el buffer', async () => {
    const first = Buffer.from('ab');
    const second = Buffer.from('cd');
    async function* source(): AsyncGenerator<Buffer> {
      yield first;
      first[0] = 0x7a;
      first[1] = 0x7a;
      yield second;
    }
    const body = await readBoundedBody(source());
    assert.equal(body.toString('utf8'), 'abcd');
  });

  it('no eleva el tope y no recorta según Content-Length', async () => {
    await assert.rejects(
      readBoundedBody(chunksOf([Buffer.from('abcd')]), {
        maxBytes: OCR_BODY_MAX_BYTES + 1,
      }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    const body = await readBoundedBody(chunksOf([Buffer.from('abcd')]), {
      contentLength: 1,
      contentEncoding: 'identity',
      contentType: 'application/octet-stream',
    });
    assert.equal(body.toString('utf8'), 'abcd');
  });

  it('rechaza gzip sin leer ni inflar el cuerpo', async () => {
    const raw = Buffer.from('synthetic certificate');
    const encoded = gzipSync(raw);
    let pulls = 0;
    async function* source(): AsyncGenerator<Buffer> {
      pulls += 1;
      yield encoded;
    }
    await assert.rejects(
      readBoundedBody(source(), { contentEncoding: 'gzip' }),
      (error: unknown) => isContractError(error, 'ENCODED'),
    );
    assert.equal(pulls, 0);
    assert.notEqual(encoded.toString('utf8'), raw.toString('utf8'));
  });

  it('una desconexión no devuelve bytes parciales ni el fragmento en el error', async () => {
    async function* source(): AsyncGenerator<Buffer> {
      yield Buffer.from('super-secret-chunk');
      throw new Error('socket hang up with super-secret-chunk');
    }
    await assert.rejects(readBoundedBody(source()), (error: unknown) => {
      assert.equal(isContractError(error, 'DISCONNECTED'), true);
      const message = error instanceof Error ? error.message : '';
      assert.equal(message.includes('super-secret-chunk'), false);
      assert.equal(message.includes('socket'), false);
      return true;
    });
  });
});

describe('respuesta JSON', () => {
  it('serializa páginas ordenadas y falla si faltan, sobran o el documento está vacío', () => {
    const body = serializeOcrSuccess({
      operationId: FILE_ID,
      pageCount: 2,
      pages: [
        { pageNumber: 2, text: 'segunda' },
        { pageNumber: 1, text: 'primera' },
      ],
    });
    assert.equal(body[0], 0x7b);
    assert.deepEqual(JSON.parse(body.toString('utf8')), {
      version: 'v1',
      operationId: FILE_ID,
      pageCount: 2,
      pages: [
        { pageNumber: 1, text: 'primera' },
        { pageNumber: 2, text: 'segunda' },
      ],
    });
    assert.throws(
      () =>
        serializeOcrSuccess({
          operationId: FILE_ID,
          pageCount: 2,
          pages: [{ pageNumber: 1, text: 'solo' }],
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        serializeOcrSuccess({
          operationId: FILE_ID,
          pageCount: 1,
          pages: [
            { pageNumber: 1, text: 'a' },
            { pageNumber: 1, text: 'b' },
          ],
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        serializeOcrSuccess({
          operationId: FILE_ID,
          pageCount: 1,
          pages: [{ pageNumber: 1, text: '   ' }],
        }),
      (error: unknown) => isContractError(error, 'EMPTY_DOCUMENT'),
    );
    assert.throws(
      () =>
        serializeOcrSuccess({
          operationId: FILE_ID,
          pageCount: 6,
          pages: Array.from({ length: 6 }, (_, index) => ({
            pageNumber: index + 1,
            text: 'p',
          })),
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    const mixed = serializeOcrSuccess({
      operationId: FILE_ID,
      pageCount: 2,
      pages: [
        { pageNumber: 1, text: '   ' },
        { pageNumber: 2, text: 'marca' },
      ],
    });
    assert.equal(JSON.parse(mixed.toString('utf8')).pages[1].text, 'marca');
    assert.throws(
      () =>
        serializeOcrSuccess({
          operationId: FILE_ID,
          pageCount: 1,
          pages: [
            {
              pageNumber: 1,
              text: 'ok',
              error: 'no',
            } as { pageNumber: number; text: string },
          ],
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });

  it('acepta el JSON UTF-8 de 16 MiB y rechaza un byte más sin truncar', () => {
    const operationId = FILE_ID;
    const empty = Buffer.byteLength(
      JSON.stringify({
        version: 'v1',
        operationId,
        pageCount: 1,
        pages: [{ pageNumber: 1, text: '' }],
      }),
    );
    const room = OCR_RESPONSE_MAX_BYTES - empty;
    const exact = serializeOcrSuccess({
      operationId,
      pageCount: 1,
      pages: [{ pageNumber: 1, text: 'a'.repeat(room) }],
    });
    assert.equal(exact.byteLength, OCR_RESPONSE_MAX_BYTES);
    assert.throws(
      () =>
        serializeOcrSuccess({
          operationId,
          pageCount: 1,
          pages: [{ pageNumber: 1, text: 'a'.repeat(room + 1) }],
        }),
      (error: unknown) => isContractError(error, 'RESPONSE_TOO_LARGE'),
    );
    const multibyteCount = Math.floor(room / 2) + 1;
    const multibyteJson = JSON.stringify({
      version: 'v1',
      operationId,
      pageCount: 1,
      pages: [{ pageNumber: 1, text: 'á'.repeat(multibyteCount) }],
    });
    assert.ok(multibyteJson.length <= OCR_RESPONSE_MAX_BYTES);
    assert.ok(Buffer.byteLength(multibyteJson) > OCR_RESPONSE_MAX_BYTES);
    assert.throws(
      () =>
        serializeOcrSuccess({
          operationId,
          pageCount: 1,
          pages: [{ pageNumber: 1, text: 'á'.repeat(multibyteCount) }],
        }),
      (error: unknown) => isContractError(error, 'RESPONSE_TOO_LARGE'),
    );
  });

  it('el error solo lleva version, code y requestId, sin ids correlacionados', () => {
    const requestId = 'ab'.repeat(16);
    const body = serializeOcrError({
      code: 'QUOTA',
      requestId,
      operationId: FILE_ID,
      nonce: '0123456789abcdef0123456789abcdef',
      contentSha256: 'c'.repeat(64),
    });
    assert.deepEqual(JSON.parse(body.toString('utf8')), {
      version: 'v1',
      code: 'QUOTA',
      requestId,
    });
    assert.throws(
      () =>
        serializeOcrError({
          code: 'QUOTA',
          requestId,
          nonce: requestId,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        serializeOcrError({
          code: 'QUOTA',
          requestId: FILE_ID,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        serializeOcrError({
          code: 'NOT_A_CODE' as 'QUOTA',
          requestId,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });
});

describe('alcance del slice', () => {
  it('declara Vision 6.1.1 y no referencia pdf-lib', () => {
    const pkg = JSON.parse(
      readFileSync(path.join(ROOT, 'package.json'), 'utf8'),
    ) as {
      dependencies?: Record<string, string>;
      devDependencies?: unknown;
      scripts?: { start?: unknown };
    };
    assert.deepEqual(pkg.dependencies, {
      '@google-cloud/firestore': '9.3.1',
      '@google-cloud/vision': '6.1.1',
    });
    assert.equal(pkg.devDependencies, undefined);
    // Task5 agrega el entrypoint de Cloud Run: node directo, sin tsx ni build.
    assert.equal(pkg.scripts?.start, 'node src/main.ts');
    const banned = ['pdf-lib', 'firebase-admin', 'firebase'];
    const files = walk(path.join(ROOT, 'src'));
    assert.ok(files.length > 0);
    for (const file of files) {
      const text = readFileSync(file, 'utf8');
      for (const name of banned) {
        assert.equal(text.includes(name), false, `${file} ${name}`);
      }
      if (!file.endsWith(`${path.sep}vision-text-reader.ts`)) {
        assert.equal(text.includes('@google-cloud/vision'), false, file);
      }
    }
  });
});

function walk(dir: string): string[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(full) : [full];
  });
}
