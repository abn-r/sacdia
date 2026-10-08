import assert from 'node:assert/strict';
import { createHash, createHmac } from 'node:crypto';
import { Buffer } from 'node:buffer';
import { describe, it } from 'node:test';
import {
  OCR_BODY_MAX_BYTES,
  OCR_HEADERS,
  OcrContractError,
  type OcrErrorCode,
} from '../src/ocr/ocr-contract.ts';
import {
  canonicalOcrSigningString,
  signOcrRequest,
  verifyOcrRequest,
  type OcrCanonicalFields,
  type OcrSignedRequest,
  type OcrVerification,
  type RawHeader,
} from '../src/auth/ocr-signature.ts';
import { createSignatureFixture } from './support/ocr-fixture.ts';

const SECRET = Buffer.from('0123456789abcdef0123456789abcdef');
const PREVIOUS_SECRET = Buffer.from('fedcba9876543210fedcba9876543210');
const HISTORICAL_SECRET = Buffer.from('test-key-ocr-v1');
const BODY = Buffer.from('synthetic certificate');
const SHA256 =
  '97f9d8301938ef5542f5ac8023d73f35749811eddc5a06844dd82433fe7b6de0';
const SIGNATURE =
  '1c3f8c18c5816ff53d2b84fa1e773eac19d8cd3def3d95137085b385c6401b6e';
const PDF_FIVE_SIGNATURE =
  '6d3191a3d92334b26d4f9174c80112ce9620e6659264e3bf3f18613c223a648d';
const HISTORICAL_IMAGE_SIGNATURE =
  'ef8af7bd363e2ea8668a71db8b03a825e52b8a1d9a913408b7dbafc808d11dbd';
const HISTORICAL_PDF_SIGNATURE =
  'a3a278d6c6bbda80cffe1b61322ee75bf887c28ddfc033dd65b75d02c9a093f2';
const NOW = new Date(1_759_420_000 * 1000);
const FIELDS: OcrCanonicalFields = {
  environment: 'development',
  kid: 'k-current',
  operationId: '11111111-1111-4111-8111-111111111111',
  issuedAt: '2026-10-02T15:04:05.006Z',
  mime: 'image/jpeg',
  contentLength: BODY.length,
  pageCount: 1,
  timestamp: 1_759_420_000,
  nonce: '0123456789abcdef0123456789abcdef',
  contentSha256: SHA256,
};

const CANONICAL =
  [
    'v1',
    'POST',
    '/v1/ocr',
    FIELDS.environment,
    FIELDS.kid,
    FIELDS.operationId,
    FIELDS.issuedAt,
    FIELDS.mime,
    String(FIELDS.contentLength),
    String(FIELDS.pageCount),
    String(FIELDS.timestamp),
    FIELDS.nonce,
    FIELDS.contentSha256,
  ].join('\n') + '\n';

const RING = {
  environment: 'development',
  keys: [
    { kid: 'k-current', secret: SECRET },
    { kid: 'k-previous', secret: PREVIOUS_SECRET },
  ],
};

function signVector(body: Uint8Array = BODY) {
  return signOcrRequest({
    environment: FIELDS.environment,
    kid: FIELDS.kid,
    secret: SECRET,
    operationId: FIELDS.operationId,
    issuedAt: FIELDS.issuedAt,
    mime: FIELDS.mime,
    pageCount: FIELDS.pageCount,
    timestamp: FIELDS.timestamp,
    nonce: FIELDS.nonce,
    body,
  });
}

function verify(
  request: OcrSignedRequest,
  body: Uint8Array = BODY,
  ring = RING,
  now = NOW,
) {
  return verifyOcrRequest({
    ring,
    method: request.method,
    path: request.path,
    headers: request.headers,
    body,
    now,
  });
}

function replaceHeader(
  headers: readonly RawHeader[],
  name: string,
  value: string,
): RawHeader[] {
  return headers.map(([header, current]) =>
    header === name ? [header, value] : [header, current],
  );
}

function isContractError(error: unknown, code: string): boolean {
  return error instanceof OcrContractError && error.code === code;
}

function invertHeaderCase(name: string): string {
  return [...name]
    .map((char) =>
      char === char.toLowerCase() ? char.toUpperCase() : char.toLowerCase(),
    )
    .join('');
}

function rejected(
  result: OcrVerification,
): asserts result is { ok: false; code: OcrErrorCode } {
  assert.equal(result.ok, false);
}

async function expectSilent(run: () => void): Promise<void> {
  /* eslint-disable no-console -- la prueba sustituye la consola para afirmar silencio */
  const names = ['log', 'info', 'warn', 'error', 'debug'] as const;
  const original = names.map((name) => console[name]);
  const calls: unknown[][] = [];
  for (const name of names) {
    console[name] = (...args: unknown[]) => {
      calls.push(args);
    };
  }
  let caught: unknown;
  try {
    run();
  } catch (error) {
    caught = error;
  } finally {
    names.forEach((name, index) => {
      console[name] = original[index] as (typeof console)[typeof name];
    });
  }
  assert.deepEqual(calls, []);
  if (caught) throw caught;
  /* eslint-enable no-console */
}

describe('vectores dorados', () => {
  it('conserva el vector histórico de 15 bytes fuera del runtime', () => {
    const pdfCanonical = CANONICAL.replace(
      'image/jpeg',
      'application/pdf',
    ).replace('\n21\n1\n', '\n21\n5\n');
    assert.equal(
      createHmac('sha256', HISTORICAL_SECRET).update(CANONICAL).digest('hex'),
      HISTORICAL_IMAGE_SIGNATURE,
    );
    assert.equal(
      createHmac('sha256', HISTORICAL_SECRET)
        .update(pdfCanonical)
        .digest('hex'),
      HISTORICAL_PDF_SIGNATURE,
    );
    assert.throws(
      () =>
        signOcrRequest({
          environment: FIELDS.environment,
          kid: FIELDS.kid,
          secret: HISTORICAL_SECRET,
          operationId: FIELDS.operationId,
          issuedAt: FIELDS.issuedAt,
          mime: 'image/jpeg',
          pageCount: 1,
          timestamp: FIELDS.timestamp,
          nonce: FIELDS.nonce,
          body: BODY,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        signOcrRequest({
          environment: FIELDS.environment,
          kid: FIELDS.kid,
          secret: Buffer.alloc(31),
          operationId: FIELDS.operationId,
          issuedAt: FIELDS.issuedAt,
          mime: 'image/jpeg',
          pageCount: 1,
          timestamp: FIELDS.timestamp,
          nonce: FIELDS.nonce,
          body: BODY,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    const verified = verifyOcrRequest({
      ring: {
        environment: FIELDS.environment,
        keys: [{ kid: FIELDS.kid, secret: HISTORICAL_SECRET }],
      },
      method: 'POST',
      path: '/v1/ocr',
      headers: [
        ['X-Ocr-Version', 'v1'],
        ['X-Ocr-Env', FIELDS.environment],
        ['X-Ocr-Kid', FIELDS.kid],
        ['X-Ocr-Operation-Id', FIELDS.operationId],
        ['X-Ocr-Issued-At', FIELDS.issuedAt],
        ['X-Ocr-Content-Type', FIELDS.mime],
        ['X-Ocr-Content-Length', String(BODY.length)],
        ['X-Ocr-Page-Count', '1'],
        ['X-Ocr-Timestamp', String(FIELDS.timestamp)],
        ['X-Ocr-Nonce', FIELDS.nonce],
        ['X-Ocr-Content-SHA256', SHA256],
        ['X-Ocr-Signature', HISTORICAL_IMAGE_SIGNATURE],
      ],
      body: BODY,
      now: NOW,
    });
    assert.equal(verified.ok, false);
  });

  it('fija imagen/1 y pdf/5', () => {
    const image = signOcrRequest({
      environment: FIELDS.environment,
      kid: FIELDS.kid,
      secret: SECRET,
      operationId: FIELDS.operationId,
      issuedAt: FIELDS.issuedAt,
      mime: 'image/jpeg',
      pageCount: 1,
      timestamp: FIELDS.timestamp,
      nonce: FIELDS.nonce,
      body: BODY,
    });
    const pdf = signOcrRequest({
      environment: FIELDS.environment,
      kid: FIELDS.kid,
      secret: SECRET,
      operationId: FIELDS.operationId,
      issuedAt: FIELDS.issuedAt,
      mime: 'application/pdf',
      pageCount: 5,
      timestamp: FIELDS.timestamp,
      nonce: FIELDS.nonce,
      body: BODY,
    });

    assert.equal(image.signature, SIGNATURE);
    assert.equal(pdf.signature, PDF_FIVE_SIGNATURE);
  });
});

describe('vector independiente de firma', () => {
  it('reproduce el HMAC-SHA256 de la cuerda canónica conocida', () => {
    const digest = createHash('sha256').update(BODY).digest('hex');
    assert.equal(digest, SHA256);
    const independent = createHmac('sha256', SECRET)
      .update(CANONICAL)
      .digest('hex');
    assert.equal(independent, SIGNATURE);
    assert.equal(canonicalOcrSigningString(FIELDS), CANONICAL);
    const signed = signVector();
    assert.equal(signed.signature, SIGNATURE);
    assert.equal(signed.method, 'POST');
    assert.equal(signed.path, '/v1/ocr');
    assert.equal(
      signed.headers.find(([name]) => name === OCR_HEADERS.contentSha256)?.[1],
      SHA256,
    );
    assert.equal(verify(signed).ok, true);
  });

  it('separa entorno+kid aunque su concatenación coincida', () => {
    const left = canonicalOcrSigningString({
      ...FIELDS,
      environment: 'ab',
      kid: 'c',
    });
    const right = canonicalOcrSigningString({
      ...FIELDS,
      environment: 'a',
      kid: 'bc',
    });
    assert.notEqual(left, right);
    assert.throws(
      () =>
        canonicalOcrSigningString({
          ...FIELDS,
          environment: 'ab\nc',
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });
});

describe('firma del cuerpo real', () => {
  it('rechaza bytes alterados aunque los headers firmados no cambien', async () => {
    const fixture = createSignatureFixture();
    const request = fixture.signRequest(BODY);
    assert.equal(await fixture.authenticate(request, BODY), true);
    const tampered = Buffer.from(BODY);
    tampered[0] ^= 1;
    assert.equal(await fixture.authenticate(request, tampered), false);
    assert.equal(fixture.visionCallCount(), 0);
  });

  it('rechaza cada campo firmado, el método y el path si cambian sin volver a firmar', () => {
    const signed = signVector();
    assert.equal(verify(signed).ok, true);
    const cases: Array<[string, OcrSignedRequest]> = [
      [
        'env',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.environment,
            'production',
          ),
        },
      ],
      [
        'kid',
        {
          ...signed,
          headers: replaceHeader(signed.headers, OCR_HEADERS.kid, 'k-previous'),
        },
      ],
      [
        'operation',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.operationId,
            '22222222-2222-4222-8222-222222222222',
          ),
        },
      ],
      [
        'issuedAt',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.issuedAt,
            '2026-10-02T15:04:05.007Z',
          ),
        },
      ],
      [
        'mime',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.contentType,
            'image/png',
          ),
        },
      ],
      [
        'length',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.contentLength,
            '20',
          ),
        },
      ],
      [
        'pageCount',
        {
          ...signed,
          headers: replaceHeader(signed.headers, 'X-Ocr-Page-Count', '4'),
        },
      ],
      [
        'timestamp',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.timestamp,
            String(FIELDS.timestamp + 1),
          ),
        },
      ],
      [
        'nonce',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.nonce,
            'ffffffffffffffffffffffffffffffff',
          ),
        },
      ],
      [
        'sha',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.contentSha256,
            `${SHA256.slice(0, -1)}1`,
          ),
        },
      ],
      [
        'signature',
        {
          ...signed,
          headers: replaceHeader(
            signed.headers,
            OCR_HEADERS.signature,
            `${SIGNATURE.slice(0, -1)}1`,
          ),
        },
      ],
      ['method', { ...signed, method: 'GET' }],
      ['path', { ...signed, path: '/v1/ocr/' }],
      ['query', { ...signed, path: '/v1/ocr?x=1' }],
      [
        'version',
        {
          ...signed,
          headers: replaceHeader(signed.headers, OCR_HEADERS.version, 'v2'),
        },
      ],
    ];
    for (const [label, request] of cases) {
      assert.equal(verify(request).ok, false, label);
    }
  });

  it('rechaza headers duplicados y metadata X-Ocr desconocida', () => {
    const signed = signVector();
    assert.equal(verify(signed).ok, true);
    const duplicate = verify({
      ...signed,
      headers: [
        ...signed.headers,
        [OCR_HEADERS.nonce, 'ffffffffffffffffffffffffffffffff'],
      ],
    });
    rejected(duplicate);
    assert.equal(duplicate.code, 'INVALID_CONTRACT');
    const unknown = verify({
      ...signed,
      headers: [...signed.headers, ['X-Ocr-User', 'person-1']],
    });
    assert.equal(unknown.ok, false);
    const withTransport = verify({
      ...signed,
      headers: [
        ...signed.headers,
        ['Content-Length', '999999'],
        ['Host', 'ocr.internal'],
      ],
    });
    assert.equal(withTransport.ok, true);
  });

  it('acepta el mismo request firmado con nombres en minúsculas y en mayúsculas mixtas', () => {
    const signed = signVector();
    const canonical = verify(signed);
    assert.equal(canonical.ok, true);
    const lower = verify({
      ...signed,
      headers: signed.headers.map(([name, value]) => [
        name.toLowerCase(),
        value,
      ]),
    });
    assert.equal(lower.ok, true);
    if (!canonical.ok || !lower.ok) return;
    assert.equal(lower.digest, canonical.digest);
    assert.equal(lower.nonce, canonical.nonce);
    assert.equal(lower.pageCount, canonical.pageCount);
    const mixed = verify({
      ...signed,
      headers: signed.headers.map(([name, value]) => [
        invertHeaderCase(name),
        value,
      ]),
    });
    assert.equal(mixed.ok, true);
    if (!mixed.ok) return;
    assert.equal(mixed.operationId, canonical.operationId);
  });

  it('rechaza un duplicado que solo cambia la capitalización', () => {
    const signed = signVector();
    const duplicate = verify({
      ...signed,
      headers: [
        ...signed.headers,
        ['x-ocr-nonce', 'ffffffffffffffffffffffffffffffff'],
      ],
    });
    rejected(duplicate);
    assert.equal(duplicate.code, 'INVALID_CONTRACT');
    for (const name of ['x-ocr-user', 'X-OCR-USER']) {
      const unknown = verify({
        ...signed,
        headers: [...signed.headers, [name, 'person-1']],
      });
      assert.equal(unknown.ok, false, name);
      if (unknown.ok) return;
      assert.equal(unknown.code, 'INVALID_CONTRACT', name);
    }
  });

  it('rechaza nonce corto, kid ausente del llavero y MIME con espacios', () => {
    assert.equal(verify(signVector()).ok, true);
    assert.throws(
      () =>
        signOcrRequest({
          ...vectorInput(),
          nonce: 'a'.repeat(31),
          secret: SECRET,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        signOcrRequest({
          ...vectorInput(),
          nonce: 'A'.repeat(32),
          secret: SECRET,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        signOcrRequest({
          ...vectorInput(),
          mime: 'image/jpeg ',
          secret: SECRET,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    const unknownKid = signOcrRequest({
      ...vectorInput(),
      kid: 'k-unknown',
      secret: SECRET,
    });
    const result = verify(unknownKid);
    rejected(result);
    assert.equal(result.code, 'UNAUTHORIZED');
    const longNonce = signOcrRequest({
      ...vectorInput(),
      nonce: 'ab'.repeat(32),
      secret: SECRET,
    });
    assert.equal(verify(longNonce).ok, true);
    assert.throws(
      () =>
        signOcrRequest({
          ...vectorInput(),
          nonce: 'ab'.repeat(33),
          secret: SECRET,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });

  it('acepta la clave anterior y no acepta un secreto vacío', () => {
    const previous = signOcrRequest({
      ...vectorInput(),
      kid: 'k-previous',
      secret: PREVIOUS_SECRET,
    });
    assert.equal(verify(previous).ok, true);
    assert.throws(
      () => signOcrRequest({ ...vectorInput(), secret: Buffer.alloc(0) }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });

  it('tolera 120 segundos de sesgo y rechaza 121 en ambos sentidos', () => {
    const base = FIELDS.timestamp;
    for (const delta of [-120, 120]) {
      const signed = signOcrRequest({
        ...vectorInput(),
        timestamp: base + delta,
        secret: SECRET,
      });
      assert.equal(verify(signed).ok, true, String(delta));
    }
    for (const delta of [-121, 121]) {
      const signed = signOcrRequest({
        ...vectorInput(),
        timestamp: base + delta,
        secret: SECRET,
      });
      const result = verify(signed);
      rejected(result);
      assert.equal(result.code, 'INVALID_CONTRACT');
    }
  });

  it('rechaza un reloj inválido en lugar de aceptar la firma', () => {
    const signed = signVector();
    assert.equal(verify(signed).ok, true);
    const invalid = verify(signed, BODY, RING, new Date(Number.NaN));
    rejected(invalid);
    assert.equal(invalid.code, 'INVALID_CONTRACT');
  });

  it('no aplica en la firma la ventana de siete días del issuedAt', () => {
    const signed = signOcrRequest({
      ...vectorInput(),
      issuedAt: '2020-01-01T00:00:00.000Z',
      secret: SECRET,
    });
    assert.equal(verify(signed).ok, true);
    assert.throws(
      () =>
        signOcrRequest({
          ...vectorInput(),
          issuedAt: '2026-02-31T00:00:00.000Z',
          secret: SECRET,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
    assert.throws(
      () =>
        signOcrRequest({
          ...vectorInput(),
          issuedAt: '2026-10-02T15:04:05.006+00:00',
          secret: SECRET,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });

  it('separa entornos aunque compartan los mismos bytes de secreto', async () => {
    const shared = Buffer.alloc(32, 0x11);
    const development = createSignatureFixture({
      environment: 'development',
      secret: shared,
    });
    const staging = createSignatureFixture({
      environment: 'staging',
      secret: shared,
    });
    const request = development.signRequest(BODY);
    assert.equal(await development.authenticate(request, BODY), true);
    assert.equal(await staging.authenticate(request, BODY), false);
    const forged = verify(request, BODY, {
      environment: 'staging',
      keys: [{ kid: 'k-current', secret: shared }],
    });
    rejected(forged);
    assert.equal(forged.code, 'FORBIDDEN');
  });

  it('no firma un cuerpo mayor de 10 MiB y clasifica la firma antes del tamaño', () => {
    assert.throws(
      () => signVector(Buffer.alloc(OCR_BODY_MAX_BYTES + 1)),
      (error: unknown) => isContractError(error, 'PAYLOAD_TOO_LARGE'),
    );
    const signed = signVector();
    assert.equal(verify(signed).ok, true);
    const badSignature = verify(
      {
        ...signed,
        headers: replaceHeader(
          signed.headers,
          OCR_HEADERS.signature,
          'ab'.repeat(32),
        ),
      },
      Buffer.alloc(OCR_BODY_MAX_BYTES + 1),
    );
    rejected(badSignature);
    assert.equal(badSignature.code, 'UNAUTHORIZED');
  });

  it('no escribe cuerpo, headers ni secreto en la consola', async () => {
    await expectSilent(() => {
      const signed = signVector();
      assert.equal(verify(signed).ok, true);
      verify({
        ...signed,
        headers: replaceHeader(
          signed.headers,
          OCR_HEADERS.signature,
          '00'.repeat(32),
        ),
      });
    });
  });
});

function vectorInput() {
  return {
    environment: FIELDS.environment,
    kid: FIELDS.kid,
    operationId: FIELDS.operationId,
    issuedAt: FIELDS.issuedAt,
    mime: FIELDS.mime,
    pageCount: FIELDS.pageCount,
    timestamp: FIELDS.timestamp,
    nonce: FIELDS.nonce,
    body: BODY,
  };
}

function independentRequest(
  pageCountText: string,
  mime: string,
  over: { nonce?: string; operationId?: string } = {},
): OcrSignedRequest {
  const nonce = over.nonce ?? FIELDS.nonce;
  const operationId = over.operationId ?? FIELDS.operationId;
  const contentSha256 = createHash('sha256').update(BODY).digest('hex');
  const signature = createHmac('sha256', SECRET)
    .update(
      [
        'v1',
        'POST',
        '/v1/ocr',
        FIELDS.environment,
        FIELDS.kid,
        operationId,
        FIELDS.issuedAt,
        mime,
        String(BODY.length),
        pageCountText,
        String(FIELDS.timestamp),
        nonce,
        contentSha256,
      ].join('\n') + '\n',
    )
    .digest('hex');
  return {
    method: 'POST',
    path: '/v1/ocr',
    signature,
    headers: [
      [OCR_HEADERS.version, 'v1'],
      [OCR_HEADERS.environment, FIELDS.environment],
      [OCR_HEADERS.kid, FIELDS.kid],
      [OCR_HEADERS.operationId, operationId],
      [OCR_HEADERS.issuedAt, FIELDS.issuedAt],
      [OCR_HEADERS.contentType, mime],
      [OCR_HEADERS.contentLength, String(BODY.length)],
      ['X-Ocr-Page-Count', pageCountText],
      [OCR_HEADERS.timestamp, String(FIELDS.timestamp)],
      [OCR_HEADERS.nonce, nonce],
      [OCR_HEADERS.contentSha256, contentSha256],
      [OCR_HEADERS.signature, signature],
    ],
  };
}

describe('conteo de páginas firmado', () => {
  it('acepta un PDF de 5 con el HMAC independiente y lo expone', () => {
    const request = independentRequest('5', 'application/pdf');
    assert.equal(request.signature, PDF_FIVE_SIGNATURE);
    const verified = verify(request);
    assert.equal(verified.ok, true);
    if (!verified.ok) return;
    assert.equal(verified.pageCount, 5);
    const signed = signOcrRequest({
      ...vectorInput(),
      mime: 'application/pdf',
      pageCount: 5,
      secret: SECRET,
    });
    assert.equal(signed.signature, PDF_FIVE_SIGNATURE);
  });

  it('invalidar solo el conteo rompe la firma', () => {
    const request = independentRequest('5', 'application/pdf');
    const tampered = verify({
      ...request,
      headers: replaceHeader(request.headers, 'X-Ocr-Page-Count', '4'),
    });
    assert.equal(tampered.ok, false);
    if (tampered.ok) return;
    assert.equal(tampered.code, 'UNAUTHORIZED');
  });

  it('exige X-Ocr-Page-Count exactamente una vez, con nombre case-insensitive', () => {
    const request = independentRequest('5', 'application/pdf');
    const once = verify(request);
    assert.equal(once.ok, true);
    const duplicate = verify({
      ...request,
      headers: [...request.headers, ['X-Ocr-Page-Count', '5']],
    });
    rejected(duplicate);
    assert.equal(duplicate.code, 'INVALID_CONTRACT');
    const duplicateCase = verify({
      ...request,
      headers: [...request.headers, ['x-ocr-page-count', '5']],
    });
    rejected(duplicateCase);
    assert.equal(duplicateCase.code, 'INVALID_CONTRACT');
    const missing = verify({
      ...request,
      headers: request.headers.filter(([name]) => name !== 'X-Ocr-Page-Count'),
    });
    rejected(missing);
    assert.equal(missing.code, 'INVALID_CONTRACT');
    const lowered = verify({
      ...request,
      headers: request.headers.map(([name, value]) =>
        name === 'X-Ocr-Page-Count'
          ? ['x-ocr-page-count', value]
          : [name, value],
      ),
    });
    assert.equal(lowered.ok, true);
    if (!lowered.ok) return;
    assert.equal(lowered.pageCount, 5);
  });

  it('rechaza conteos fuera de gramática', () => {
    for (const text of ['0', '6', '05', '+1', ' 1', '1.0', '2a']) {
      const result = verify(independentRequest(text, 'application/pdf'));
      assert.equal(result.ok, false, text);
      if (result.ok) return;
      assert.equal(result.code, 'INVALID_CONTRACT', text);
    }
  });

  it('rechaza una imagen cuyo conteo no es 1', () => {
    const result = verify(independentRequest('2', 'image/jpeg'));
    assert.equal(result.ok, false);
    if (result.ok) return;
    assert.equal(result.code, 'INVALID_CONTRACT');
  });

  it('no firma 0, 6 ni una imagen con 2', () => {
    for (const pageCount of [0, 6]) {
      assert.throws(
        () =>
          signOcrRequest({
            ...vectorInput(),
            mime: 'application/pdf',
            pageCount,
            secret: SECRET,
          }),
        (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
      );
    }
    assert.throws(
      () =>
        signOcrRequest({
          ...vectorInput(),
          pageCount: 2,
          secret: SECRET,
        }),
      (error: unknown) => isContractError(error, 'INVALID_CONTRACT'),
    );
  });
});
