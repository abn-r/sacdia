import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import { describe, it } from 'node:test';
import {
  createVisionTextReader,
  type VisionCallOptions,
  type VisionClientConfig,
  type VisionClientConstructor,
} from '../src/vision/vision-text-reader.ts';
import { jpegBytes, pdfBytes } from './support/signed-ocr.ts';

describe('adaptador Vision inyectable', () => {
  it('construye un cliente US perezoso, sin clave ni timeout de constructor', async () => {
    const fake = fakeClient();
    const reader = createVisionTextReader({ Client: fake.Client });
    assert.equal(fake.constructed.length, 0);
    await reader.read({
      mime: 'image/jpeg',
      content: jpegBytes(),
      pageCount: 1,
      remainingMs: 40_000,
    });
    await reader.read({
      mime: 'image/jpeg',
      content: jpegBytes(),
      pageCount: 1,
      remainingMs: 10_000,
    });
    assert.equal(fake.constructed.length, 1);
    const config = fake.constructed[0];
    assert.ok(config);
    assert.equal(config.apiEndpoint, 'us-vision.googleapis.com');
    assert.equal(config.fallback, false);
    assert.equal(config['grpc.max_send_message_length'], 12 * 1024 * 1024);
    assert.equal(config['grpc.max_receive_message_length'], 16 * 1024 * 1024);
    for (const forbidden of [
      'keyFilename',
      'credentials',
      'apiKey',
      'timeout',
      'retry',
      'projectId',
    ]) {
      assert.equal(Object.hasOwn(config, forbidden), false, forbidden);
    }
    const first = fake.calls[0];
    const second = fake.calls[1];
    assert.equal(first?.method, 'images');
    assert.deepEqual(first?.options, {
      timeout: 25_000,
      retry: { retryCodes: [] },
    });
    assert.deepEqual(second?.options, {
      timeout: 10_000,
      retry: { retryCodes: [] },
    });
    assert.notEqual(
      first?.options.retry.retryCodes,
      second?.options.retry.retryCodes,
    );
    await reader.close();
    assert.equal(fake.closed, 1);
    await reader.close();
    assert.equal(fake.closed, 1);
  });

  it('envía el PDF en línea con las páginas 1..N y no llama images', async () => {
    const fake = fakeClient();
    const reader = createVisionTextReader({ Client: fake.Client });
    const body = pdfBytes();
    const read = await reader.read({
      mime: 'application/pdf',
      content: body,
      pageCount: 5,
      remainingMs: 25_000,
    });
    assert.equal(fake.calls.length, 1);
    assert.equal(fake.calls[0]?.method, 'files');
    const request = fake.calls[0]?.request as {
      requests: Array<{
        inputConfig: { mimeType: string; content: Buffer };
        pages: number[];
      }>;
    };
    assert.equal(request.requests[0]?.inputConfig.mimeType, 'application/pdf');
    assert.deepEqual(request.requests[0]?.pages, [1, 2, 3, 4, 5]);
    assert.ok(Buffer.isBuffer(request.requests[0]?.inputConfig.content));
    assert.ok(request.requests[0]?.inputConfig.content.equals(body));
    assert.equal(read.pages.length, 5);
    assert.deepEqual(
      read.pages.map((page) => page.pageNumber),
      [1, 2, 3, 4, 5],
    );
    await reader.close();
  });
});

function fakeClient(): {
  Client: VisionClientConstructor;
  constructed: VisionClientConfig[];
  calls: Array<{
    method: string;
    request: unknown;
    options: VisionCallOptions;
  }>;
  closed: number;
} {
  const constructed: VisionClientConfig[] = [];
  const calls: Array<{
    method: string;
    request: unknown;
    options: VisionCallOptions;
  }> = [];
  const closed = { count: 0 };
  class Client {
    constructor(config: VisionClientConfig) {
      constructed.push(config);
    }

    async batchAnnotateImages(request: unknown, options: VisionCallOptions) {
      calls.push({ method: 'images', request, options });
      return [{ responses: [{ fullTextAnnotation: { text: 'hola' } }] }];
    }

    async batchAnnotateFiles(request: unknown, options: VisionCallOptions) {
      calls.push({ method: 'files', request, options });
      return [
        {
          responses: [
            {
              totalPages: 5,
              responses: [1, 2, 3, 4, 5].map((pageNumber) => ({
                context: { pageNumber },
                fullTextAnnotation: { text: `p${pageNumber}` },
              })),
            },
          ],
        },
      ];
    }

    close() {
      closed.count += 1;
    }
  }
  return {
    Client: Client as unknown as VisionClientConstructor,
    constructed,
    calls,
    get closed() {
      return closed.count;
    },
  };
}
