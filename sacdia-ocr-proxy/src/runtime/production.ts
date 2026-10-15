import type { AddressInfo } from 'node:net';
import type { Server } from 'node:http';
import {
  loadRuntimeConfig,
  type RuntimeConfig,
} from '../config/runtime-config.ts';
import { createOcrHttpServer } from '../http/ocr-server.ts';
import type { OcrLedger } from '../ledger/ocr-ledger.port.ts';
import type { OcrRuntime } from '../ocr/ocr-orchestrator.ts';
import type { VisionTextReader } from '../vision/vision-text-reader.ts';

/** Contrato de Cloud Run: el contenedor escucha en todas las interfaces. */
export const PRODUCTION_HOST = '0.0.0.0';

export type ShutdownSignal = 'SIGTERM' | 'SIGINT';

export type SignalSource = {
  on(signal: ShutdownSignal, listener: () => void): unknown;
  off(signal: ShutdownSignal, listener: () => void): unknown;
};

export type Terminable = { terminate(): Promise<void> };

/**
 * Las fábricas son obligatorias a propósito: este módulo no importa ningún SDK
 * de Google, así que las pruebas nunca pueden construir un cliente real.
 */
export type ProductionDeps<Db extends Terminable> = {
  createFirestore(projectId: string): Db;
  createLedger(db: Db): OcrLedger;
  createReader(): VisionTextReader;
};

export type ProductionOptions<Db extends Terminable> = {
  env: NodeJS.ProcessEnv;
  deps: ProductionDeps<Db>;
  signals: SignalSource;
  exit: (code: number) => void;
  log: (line: string) => void;
  runtime?: Partial<Pick<OcrRuntime, 'now' | 'hrtime' | 'sleep'>>;
};

export type ProductionHandle = {
  address: string;
  port: number;
  server: Server;
  /** Se resuelve con el código de salida cuando se llamó a `exit`. */
  finished: Promise<number>;
};

const SIGNALS: readonly ShutdownSignal[] = ['SIGTERM', 'SIGINT'];

export async function startProduction<Db extends Terminable>(
  options: ProductionOptions<Db>,
): Promise<ProductionHandle> {
  const config = loadRuntimeConfig(options.env);
  const db = options.deps.createFirestore(config.projectId);
  let reader: VisionTextReader | undefined;
  let draining = false;
  let server: Server;
  try {
    const ledger = options.deps.createLedger(db);
    reader = options.deps.createReader();
    const runtime = buildRuntime(config, options, ledger, reader);
    server = createOcrHttpServer(runtime, { draining: () => draining });
    await listen(server, config.port);
  } catch (error) {
    await Promise.allSettled([reader?.close(), db.terminate()]);
    throw error;
  }
  const address = server.address() as AddressInfo;
  const activeReader = reader;

  let exited = false;
  let graceTimer: NodeJS.Timeout | undefined;
  let finish: (code: number) => void = () => undefined;
  const finished = new Promise<number>((resolve) => {
    finish = resolve;
  });

  const end = (code: number): void => {
    if (exited) return;
    exited = true;
    if (graceTimer) clearTimeout(graceTimer);
    for (const signal of SIGNALS) options.signals.off(signal, onSignal);
    options.exit(code);
    finish(code);
  };

  const force = (): void => {
    if (exited) return;
    options.log(logLine('WARNING', 'shutdown_forced'));
    server.closeAllConnections();
    end(1);
  };

  const drain = async (): Promise<void> => {
    await new Promise<void>((resolve) => {
      server.close(() => resolve());
      server.closeIdleConnections();
    });
    if (exited) return;
    const closed = await Promise.allSettled([
      activeReader.close(),
      db.terminate(),
    ]);
    if (exited) return;
    const failed = closed.some((result) => result.status === 'rejected');
    if (failed) options.log(logLine('ERROR', 'shutdown_close_failed'));
    options.log(logLine('INFO', 'shutdown_complete'));
    end(failed ? 1 : 0);
  };

  function onSignal(): void {
    if (draining) {
      force();
      return;
    }
    draining = true;
    options.log(logLine('INFO', 'shutdown_started'));
    graceTimer = setTimeout(force, config.shutdownGraceMs);
    void drain();
  }

  // Una conexión keep-alive que termina su respuesta durante el drenado se
  // cierra, para que server.close() no espere el keepAliveTimeout.
  server.on('request', (_request, response) => {
    response.on('finish', () => {
      if (draining) response.socket?.end();
    });
  });
  for (const signal of SIGNALS) options.signals.on(signal, onSignal);
  options.log(
    logLine('INFO', 'listening', {
      address: address.address,
      port: address.port,
    }),
  );
  return { address: address.address, port: address.port, server, finished };
}

function buildRuntime<Db extends Terminable>(
  config: RuntimeConfig,
  options: ProductionOptions<Db>,
  ledger: OcrLedger,
  reader: VisionTextReader,
): OcrRuntime {
  return {
    ring: config.ring,
    ledger,
    reader,
    pageLimit: config.pageLimit,
    log: (event, code) => options.log(logLine('WARNING', event, { code })),
    ...options.runtime,
  };
}

function logLine(
  severity: 'INFO' | 'WARNING' | 'ERROR',
  message: string,
  extra: Record<string, string | number> = {},
): string {
  return JSON.stringify({ severity, message, ...extra });
}

function listen(server: Server, port: number): Promise<void> {
  return new Promise<void>((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, PRODUCTION_HOST, () => {
      server.removeListener('error', reject);
      resolve();
    });
  });
}
