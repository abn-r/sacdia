import { Buffer } from 'node:buffer';
import {
  signOcrRequest,
  verifyOcrRequest,
  type OcrSignedRequest,
  type SignOcrInput,
} from '../../src/auth/ocr-signature.ts';

const DEFAULT_SECRET = Buffer.from('0123456789abcdef0123456789abcdef');
const PREVIOUS_SECRET = Buffer.from('fedcba9876543210fedcba9876543210');
const DEFAULT_NOW = new Date(1_759_420_000 * 1000);

export type SignatureFixtureOptions = {
  environment?: string;
  secret?: Buffer;
  now?: Date;
};

/**
 * Contador de prueba. Los módulos de este slice no llaman a Vision;
 * un cero aquí no es una protección durable.
 */
export function createSignatureFixture(options: SignatureFixtureOptions = {}) {
  const environment = options.environment ?? 'development';
  const secret = options.secret ?? DEFAULT_SECRET;
  const now = options.now ?? DEFAULT_NOW;
  const visionCalls = 0;
  const ring = {
    environment,
    keys: [
      { kid: 'k-current', secret },
      { kid: 'k-previous', secret: PREVIOUS_SECRET },
    ],
  };

  return {
    ring,
    now,
    signRequest(
      body: Uint8Array,
      overrides: Partial<SignOcrInput> = {},
    ): OcrSignedRequest {
      const kid = overrides.kid ?? 'k-current';
      const signingSecret =
        overrides.secret ?? (kid === 'k-previous' ? PREVIOUS_SECRET : secret);
      const mime = overrides.mime ?? 'image/jpeg';
      return signOcrRequest({
        environment,
        kid,
        secret: signingSecret,
        operationId: '11111111-1111-4111-8111-111111111111',
        issuedAt: '2026-10-02T15:04:05.006Z',
        mime,
        // Imagen del fixture: una página. overrides.pageCount la reemplaza.
        // signOcrRequest no inventa el conteo.
        pageCount: 1,
        timestamp: 1_759_420_000,
        nonce: '0123456789abcdef0123456789abcdef',
        body,
        ...overrides,
      });
    },
    async authenticate(
      request: {
        method: string;
        path: string;
        headers: OcrSignedRequest['headers'];
      },
      body: Uint8Array,
    ): Promise<boolean> {
      return verifyOcrRequest({
        ring,
        method: request.method,
        path: request.path,
        headers: request.headers,
        body,
        now,
      }).ok;
    },
    visionCallCount(): number {
      return visionCalls;
    },
  };
}
