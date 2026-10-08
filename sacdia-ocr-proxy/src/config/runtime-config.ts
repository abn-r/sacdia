import { Buffer } from 'node:buffer';
import {
  ENV_PATTERN,
  KID_PATTERN,
  type OcrKey,
  type OcrKeyRing,
} from '../auth/ocr-signature.ts';
import {
  OCR_MAX_PAGES_PER_ENV_PER_DAY,
  OcrContractError,
  resolveDailyPageLimit,
} from '../ocr/ocr-contract.ts';

export const OCR_SECRET_MIN_BYTES = 32;
export const DEFAULT_PORT = 8080;
// Cloud Run sends SIGKILL about 10 s after SIGTERM, and that window is not
// configurable. Draining must finish inside it.
export const DEFAULT_SHUTDOWN_GRACE_MS = 8_000;
export const MIN_SHUTDOWN_GRACE_MS = 100;
export const MAX_SHUTDOWN_GRACE_MS = 9_000;

const PROJECT_PATTERN = /^[a-z][a-z0-9-]{4,28}[a-z0-9]$/;
const DECIMAL_PATTERN = /^[1-9][0-9]{0,8}$/;
const BASE64_PATTERN =
  /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/;

export type RuntimeConfigIssueReason =
  'missing' | 'invalid' | 'incomplete' | 'forbidden';

export type RuntimeConfigIssue = {
  name: string;
  reason: RuntimeConfigIssueReason;
};

export type RuntimeConfig = {
  environment: string;
  ring: OcrKeyRing;
  pageLimit: number;
  projectId: string;
  port: number;
  shutdownGraceMs: number;
};

/**
 * Los mensajes solo llevan nombres de variables y una razón fija; nunca
 * valores, para que un secreto mal pegado no termine en los logs.
 */
export class RuntimeConfigError extends Error {
  readonly issues: readonly RuntimeConfigIssue[];

  constructor(issues: readonly RuntimeConfigIssue[]) {
    super(
      `invalid runtime configuration: ${issues
        .map((issue) => `${issue.name} (${issue.reason})`)
        .join(', ')}`,
    );
    this.name = 'RuntimeConfigError';
    this.issues = issues;
  }
}

/** Misma validación de ida y vuelta que sacdia-backend/src/config/ocr-proxy-secret.ts. */
export function decodeOcrSecret(value: string): Buffer | null {
  const trimmed = value.trim();
  if (!BASE64_PATTERN.test(trimmed)) return null;
  const decoded = Buffer.from(trimmed, 'base64');
  if (decoded.toString('base64') !== trimmed) return null;
  if (decoded.byteLength < OCR_SECRET_MIN_BYTES) return null;
  return decoded;
}

export function loadRuntimeConfig(env: NodeJS.ProcessEnv): RuntimeConfig {
  const issues: RuntimeConfigIssue[] = [];
  const report = (name: string, reason: RuntimeConfigIssueReason): void => {
    issues.push({ name, reason });
  };

  const environment = env.OCR_ENV;
  if (environment === undefined) report('OCR_ENV', 'missing');
  else if (!ENV_PATTERN.test(environment)) report('OCR_ENV', 'invalid');

  const current = readKey(env, 'OCR_KID_CURRENT', 'OCR_SECRET_CURRENT', report);

  const previous = readPreviousKey(env, report);
  if (current && previous && current.kid === previous.kid) {
    report('OCR_KID_PREVIOUS', 'invalid');
  }

  const pageLimit = readPageLimit(env, report);
  const port = readInteger(env, 'PORT', DEFAULT_PORT, 1, 65_535, report);
  const shutdownGraceMs = readInteger(
    env,
    'OCR_SHUTDOWN_GRACE_MS',
    DEFAULT_SHUTDOWN_GRACE_MS,
    MIN_SHUTDOWN_GRACE_MS,
    MAX_SHUTDOWN_GRACE_MS,
    report,
  );

  const projectId = env.GOOGLE_CLOUD_PROJECT;
  if (projectId === undefined) {
    report('GOOGLE_CLOUD_PROJECT', 'missing');
  } else if (
    !PROJECT_PATTERN.test(projectId) ||
    projectId.startsWith('demo-')
  ) {
    report('GOOGLE_CLOUD_PROJECT', 'invalid');
  }

  // El entrypoint de producción solo habla con el Firestore real por ADC.
  if (env.FIRESTORE_EMULATOR_HOST !== undefined) {
    report('FIRESTORE_EMULATOR_HOST', 'forbidden');
  }
  if (env.GOOGLE_APPLICATION_CREDENTIALS !== undefined) {
    report('GOOGLE_APPLICATION_CREDENTIALS', 'forbidden');
  }

  if (issues.length > 0) throw new RuntimeConfigError(issues);

  const keys: OcrKey[] = [current as OcrKey];
  if (previous) keys.push(previous);
  return {
    environment: environment as string,
    ring: { environment: environment as string, keys },
    pageLimit: pageLimit as number,
    projectId: projectId as string,
    port: port as number,
    shutdownGraceMs: shutdownGraceMs as number,
  };
}

type Report = (name: string, reason: RuntimeConfigIssueReason) => void;

function readKey(
  env: NodeJS.ProcessEnv,
  kidName: string,
  secretName: string,
  report: Report,
): OcrKey | undefined {
  const kid = env[kidName];
  const secret = env[secretName];
  let valid = true;
  if (kid === undefined) {
    report(kidName, 'missing');
    valid = false;
  } else if (!KID_PATTERN.test(kid)) {
    report(kidName, 'invalid');
    valid = false;
  }
  let decoded: Buffer | null = null;
  if (secret === undefined) {
    report(secretName, 'missing');
    valid = false;
  } else {
    decoded = decodeOcrSecret(secret);
    if (decoded === null) {
      report(secretName, 'invalid');
      valid = false;
    }
  }
  if (!valid || kid === undefined || decoded === null) return undefined;
  return { kid, secret: decoded };
}

function readPreviousKey(
  env: NodeJS.ProcessEnv,
  report: Report,
): OcrKey | undefined {
  const kid = env.OCR_KID_PREVIOUS;
  const secret = env.OCR_SECRET_PREVIOUS;
  if (kid === undefined && secret === undefined) return undefined;
  if (kid === undefined) {
    report('OCR_KID_PREVIOUS', 'incomplete');
    return undefined;
  }
  if (secret === undefined) {
    report('OCR_SECRET_PREVIOUS', 'incomplete');
    return undefined;
  }
  return readKey(env, 'OCR_KID_PREVIOUS', 'OCR_SECRET_PREVIOUS', report);
}

function readPageLimit(
  env: NodeJS.ProcessEnv,
  report: Report,
): number | undefined {
  const text = env[OCR_MAX_PAGES_PER_ENV_PER_DAY];
  if (text === undefined) return resolveDailyPageLimit(undefined);
  if (!DECIMAL_PATTERN.test(text)) {
    report(OCR_MAX_PAGES_PER_ENV_PER_DAY, 'invalid');
    return undefined;
  }
  try {
    return resolveDailyPageLimit(Number(text));
  } catch (error) {
    if (!(error instanceof OcrContractError)) throw error;
    report(OCR_MAX_PAGES_PER_ENV_PER_DAY, 'invalid');
    return undefined;
  }
}

function readInteger(
  env: NodeJS.ProcessEnv,
  name: string,
  fallback: number,
  min: number,
  max: number,
  report: Report,
): number | undefined {
  const text = env[name];
  if (text === undefined) return fallback;
  const value = DECIMAL_PATTERN.test(text) ? Number(text) : Number.NaN;
  if (!Number.isInteger(value) || value < min || value > max) {
    report(name, 'invalid');
    return undefined;
  }
  return value;
}
