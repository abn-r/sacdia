import { Firestore } from '@google-cloud/firestore';
import { Gaxios, type GaxiosOptions } from 'gaxios';
import { OcrContractError } from '../ocr/ocr-contract.ts';

const LOOPBACK_HOST = '127.0.0.1';
const STATIC_AUTHORIZATION = 'Bearer owner';
const PROJECT_PATTERN = /^demo-[a-z0-9]([a-z0-9-]{0,24}[a-z0-9])?$/;

export class InertEmulatorAuth {
  readonly universeDomain = 'googleapis.com';
  private readonly transport = new Gaxios();
  private readonly projectId: string;

  constructor(projectId: string) {
    this.projectId = projectId;
  }

  getClient(): this {
    return this;
  }

  getRequestHeaders(): Headers {
    return new Headers({ Authorization: STATIC_AUTHORIZATION });
  }

  async getAccessToken(): Promise<{ token: string }> {
    return { token: 'owner' };
  }

  getProjectId(
    callback?: (err: Error | null, projectId?: string) => void,
  ): Promise<string> | void {
    if (callback) {
      callback(null, this.projectId);
      return;
    }
    return Promise.resolve(this.projectId);
  }

  fetch(url: string, init: GaxiosOptions = {}): Promise<unknown> {
    let target: URL;
    try {
      target = new URL(url);
    } catch (error) {
      return Promise.reject(error);
    }
    if (target.protocol !== 'http:' || target.hostname !== LOOPBACK_HOST) {
      return Promise.reject(new OcrContractError('INVALID_CONTRACT'));
    }
    const headers = new Headers(init.headers);
    const authorization = headers.get('authorization');
    if (authorization == null) {
      headers.set('authorization', STATIC_AUTHORIZATION);
    } else if (authorization !== STATIC_AUTHORIZATION) {
      return Promise.reject(new OcrContractError('INVALID_CONTRACT'));
    }
    return this.transport.request({
      ...init,
      url: target.toString(),
      headers,
      maxRedirects: 0,
    });
  }
}

export type EmulatorClientSettings = {
  projectId: string;
  host: string;
  port: number;
  ssl: false;
  preferRest: true;
  ignoreUndefinedProperties: true;
  auth: InertEmulatorAuth;
  authClient: InertEmulatorAuth;
};

export function createEmulatorFirestore(
  env: NodeJS.ProcessEnv,
  connect: (settings: EmulatorClientSettings) => Firestore = (settings) =>
    new Firestore(settings),
): Firestore {
  if (hasCredentials(env) || hasCredentials(process.env)) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  const target = parseTarget(env);
  const auth = new InertEmulatorAuth(target.projectId);
  process.env.FIRESTORE_EMULATOR_HOST = `${target.host}:${target.port}`;
  process.env.GCLOUD_PROJECT = target.projectId;
  return connect({
    projectId: target.projectId,
    host: target.host,
    port: target.port,
    ssl: false,
    preferRest: true,
    ignoreUndefinedProperties: true,
    auth,
    authClient: auth,
  });
}

function hasCredentials(env: NodeJS.ProcessEnv): boolean {
  const credentials = env.GOOGLE_APPLICATION_CREDENTIALS;
  return typeof credentials === 'string' && credentials.length > 0;
}

function parseTarget(env: NodeJS.ProcessEnv): {
  host: string;
  port: number;
  projectId: string;
} {
  const rawHost = env.FIRESTORE_EMULATOR_HOST;
  const projectId = env.GCLOUD_PROJECT;
  const match = /^127\.0\.0\.1:([1-9][0-9]{0,4})$/.exec(rawHost ?? '');
  const port = match ? Number(match[1]) : Number.NaN;
  if (
    !match ||
    !Number.isInteger(port) ||
    port < 1 ||
    port > 65_535 ||
    rawHost !== `${LOOPBACK_HOST}:${port}` ||
    typeof projectId !== 'string' ||
    !PROJECT_PATTERN.test(projectId)
  ) {
    throw new OcrContractError('INVALID_CONTRACT');
  }
  return { host: LOOPBACK_HOST, port, projectId };
}
