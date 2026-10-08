import { Buffer } from 'node:buffer';
import { STATUS_CODES, createServer } from 'node:http';
import type { IncomingMessage, Server, ServerResponse } from 'node:http';
import type { Duplex } from 'node:stream';
import {
  verifyOcrBody,
  verifyOcrDeclared,
  type RawHeader,
} from '../auth/ocr-signature.ts';
import { readBoundedBody } from '../ocr/bounded-body.ts';
import {
  OCR_HEADERS_TIMEOUT_MS,
  OCR_HTTP_METHOD,
  OCR_HTTP_PATH,
  OCR_HTTP_TIMEOUT_CHECK_MS,
  OCR_REQUEST_TIMEOUT_MS,
  OcrContractError,
} from '../ocr/ocr-contract.ts';
import {
  handleOcrRequest,
  ocrErrorResult,
  type OcrHttpResult,
  type OcrRuntime,
} from '../ocr/ocr-orchestrator.ts';

const LOOPBACK = '127.0.0.1';

export type OcrListenOptions = {
  port?: number;
  bodyReadTimeoutMs?: number;
  headersTimeoutMs?: number;
  requestTimeoutMs?: number;
  connectionsCheckingIntervalMs?: number;
};

export type OcrHttpServerOptions = OcrListenOptions & {
  /** Verdadero mientras el proceso drena: toda request nueva recibe 503. */
  draining?: () => boolean;
};

export type OcrServer = {
  port: number;
  close(): Promise<void>;
};

export function createOcrHttpServer(
  runtime: OcrRuntime,
  options: OcrHttpServerOptions = {},
): Server {
  const headersTimeout = options.headersTimeoutMs ?? OCR_HEADERS_TIMEOUT_MS;
  const requestTimeout = options.requestTimeoutMs ?? OCR_REQUEST_TIMEOUT_MS;
  const active = new WeakSet<Duplex>();
  const server = createServer(
    {
      headersTimeout,
      requestTimeout,
      connectionsCheckingInterval:
        options.connectionsCheckingIntervalMs ?? OCR_HTTP_TIMEOUT_CHECK_MS,
    },
    (request, response) => {
      request.on('error', () => undefined);
      if (options.draining?.()) {
        send(response, ocrErrorResult(runtime, 'UNAVAILABLE'), request);
        return;
      }
      if (request.socket) active.add(request.socket);
      void onRequest(request, response, runtime, options.bodyReadTimeoutMs)
        .catch(() => {
          if (response.headersSent || response.writableEnded) return;
          send(response, ocrErrorResult(runtime, 'UNAVAILABLE'), request);
        })
        .finally(() => {
          if (request.socket) active.delete(request.socket);
        });
    },
  );
  server.on('clientError', (error: NodeJS.ErrnoException, socket) => {
    if (active.has(socket)) {
      socket.destroy();
      return;
    }
    if (socket.writable) {
      writeRawEnvelope(
        socket,
        ocrErrorResult(
          runtime,
          error.code === 'ERR_HTTP_REQUEST_TIMEOUT'
            ? 'DISCONNECTED'
            : 'INVALID_CONTRACT',
        ),
      );
    }
    socket.destroy();
  });
  return server;
}

export async function listenOcr(
  runtime: OcrRuntime,
  options: OcrListenOptions = {},
): Promise<OcrServer> {
  const server = createOcrHttpServer(runtime, options);
  await new Promise<void>((resolve, reject) => {
    server.once('error', reject);
    server.listen(options.port ?? 0, LOOPBACK, () => {
      server.removeListener('error', reject);
      resolve();
    });
  });
  const address = server.address();
  if (
    address == null ||
    typeof address === 'string' ||
    address.address !== LOOPBACK
  ) {
    server.close();
    throw new Error('OCR server only binds to 127.0.0.1');
  }
  return {
    port: address.port,
    async close() {
      server.closeAllConnections();
      await new Promise<void>((resolve, reject) => {
        server.close((error) => (error ? reject(error) : resolve()));
      });
      await runtime.reader.close();
    },
  };
}

async function onRequest(
  request: IncomingMessage,
  response: ServerResponse,
  runtime: OcrRuntime,
  bodyReadTimeoutMs: number | undefined,
): Promise<void> {
  const path = requestPath(request.url);
  const method = request.method ?? '';
  const headers = rawHeaderPairs(request.rawHeaders);
  if (!(method === OCR_HTTP_METHOD && path === OCR_HTTP_PATH)) {
    send(
      response,
      await handleOcrRequest(
        { method, path, headers, body: new Uint8Array() },
        runtime,
      ),
      request,
    );
    return;
  }
  const declared = verifyOcrDeclared({
    ring: runtime.ring,
    method,
    path,
    headers,
    now: runtime.now?.() ?? new Date(),
  });
  if (!declared.ok) {
    send(response, ocrErrorResult(runtime, declared.code, headers), request);
    return;
  }
  let body: Buffer;
  try {
    body = await readBoundedBody(request, {
      contentType: singleHeader(request.headers['content-type']),
      contentEncoding: singleHeader(request.headers['content-encoding']),
      timeoutMs: bodyReadTimeoutMs,
    });
  } catch (error) {
    const code =
      error instanceof OcrContractError ? error.code : 'DISCONNECTED';
    send(response, ocrErrorResult(runtime, code, headers), request);
    return;
  }
  const hashed = verifyOcrBody(declared, body);
  if (!hashed.ok) {
    send(response, ocrErrorResult(runtime, hashed.code, headers), request);
    return;
  }
  try {
    send(
      response,
      await handleOcrRequest({ method, path, headers, body }, runtime),
      request,
    );
  } catch {
    if (response.headersSent) return;
    send(response, ocrErrorResult(runtime, 'UNAVAILABLE'), request);
  }
}

function send(
  response: ServerResponse,
  result: OcrHttpResult,
  request: IncomingMessage,
): void {
  if (response.headersSent || response.writableEnded || response.destroyed) {
    return;
  }
  response.writeHead(result.status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': String(result.body.length),
  });
  response.end(result.body, () => {
    if (result.status !== 200) request.destroy();
  });
}

function writeRawEnvelope(socket: Duplex, result: OcrHttpResult): void {
  const reason = STATUS_CODES[result.status] ?? 'Error';
  const head = Buffer.from(
    `HTTP/1.1 ${result.status} ${reason}\r\n` +
      'content-type: application/json; charset=utf-8\r\n' +
      `content-length: ${result.body.length}\r\n` +
      'connection: close\r\n\r\n',
    'ascii',
  );
  socket.write(Buffer.concat([head, result.body]));
}

function requestPath(url: string | undefined): string {
  if (!url) return '';
  const query = url.indexOf('?');
  return query === -1 ? url : url.slice(0, query);
}

function singleHeader(value: string | string[] | undefined): string | null {
  if (Array.isArray(value)) return value.length === 1 ? value[0] : 'invalid';
  return value ?? null;
}

function rawHeaderPairs(raw: readonly string[]): RawHeader[] {
  const pairs: RawHeader[] = [];
  for (let index = 0; index < raw.length; index += 2) {
    const name = raw[index];
    const value = raw[index + 1];
    if (name !== undefined && value !== undefined) pairs.push([name, value]);
  }
  return pairs;
}
