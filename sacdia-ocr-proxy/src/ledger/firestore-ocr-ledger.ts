import { randomUUID } from 'node:crypto';
import type {
  DocumentReference,
  Firestore,
  Transaction,
} from '@google-cloud/firestore';
import {
  OCR_ACCEPTED_MIME_TYPES,
  OCR_BODY_MAX_BYTES,
  OCR_PAGE_COUNT_MAX,
  OcrContractError,
  resolveDailyPageLimit,
} from '../ocr/ocr-contract.ts';
import {
  isOperationExpired,
  isPurgeEligible,
  nonceSchedule,
  operationSchedule,
  quotaPurgeEligibleAt,
  utcDay,
} from './ocr-ledger-time.ts';
import type {
  AdmitInput,
  AdmitResult,
  ConfirmCallingInput,
  ConfirmCallingResult,
  PurgeInput,
  RecordInput,
  RecordResult,
  RecoverInput,
  RecoverResult,
} from './ocr-ledger.port.ts';

const DEFAULT_LEASE_MS = 60_000;
const MAX_LEASE_MS = 600_000;
const ENV_PATTERN = /^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$/;
const OPERATION_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{15,127}$/;
const NONCE_PATTERN = /^[0-9a-f]{32,64}$/;
const DIGEST_PATTERN = /^[0-9a-f]{64}$/;
const DAY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const ISSUED_AT_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
const ATTEMPT_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const MIME_TYPES = new Set<string>(OCR_ACCEPTED_MIME_TYPES);
const STATES = new Set(['PLANNED', 'CALLING', 'COMPLETE', 'UNKNOWN']);

type DocData = Record<string, string | number>;
type CollectionName = 'operations' | 'nonces' | 'quota';
type HookKind = 'admit' | 'confirmCalling' | 'recover' | 'complete' | 'unknown';

type OperationDoc = {
  state: 'PLANNED' | 'CALLING' | 'COMPLETE' | 'UNKNOWN';
  issuedAt: string;
  digest: string;
  mime: string;
  byteLength: number;
  pageCount: number;
  reservedPages: number;
  utcDay: string;
  fence: number;
  leaseExpiresAt: string;
  logicalExpiresAt: string;
  purgeEligibleAt: string;
  receivedAt: string;
  attemptId?: string;
};

export type LedgerHooks = {
  afterCommit?: (kind: HookKind) => void;
  failReread?: boolean;
};

export class FirestoreOcrLedger {
  private readonly overlays = new WeakMap<
    Transaction,
    Map<string, DocData | null>
  >();
  private readonly db: Firestore;
  private readonly hooks: LedgerHooks;

  constructor(db: Firestore, hooks: LedgerHooks = {}) {
    this.db = db;
    this.hooks = hooks;
  }

  async admit(input: AdmitInput): Promise<AdmitResult> {
    if (this.invalidAdmit(input)) return { status: 'INVALID_CONTRACT' };
    try {
      const result = await this.db.runTransaction((tx) =>
        this.stageAdmission(tx, input),
      );
      return await this.observe(
        'admit',
        result,
        () => this.rereadAdmit(input),
        {
          status: 'UNAVAILABLE',
        },
      );
    } catch {
      return this.rereadAdmit(input);
    }
  }

  async stageAdmission(
    tx: Transaction,
    input: AdmitInput,
  ): Promise<AdmitResult> {
    if (this.invalidAdmit(input)) return { status: 'INVALID_CONTRACT' };
    this.beginAttempt(tx);
    const operation = this.doc(
      'operations',
      input.environment,
      input.operationId,
    );
    const nonce = this.doc('nonces', input.environment, input.nonce);
    const quota = this.doc('quota', input.environment, utcDay(input.now));
    const operationData = await this.read(tx, operation);
    const nonceData = await this.read(tx, nonce);
    const quotaData = await this.read(tx, quota);
    if (operationData && !asOperation(operationData))
      return { status: 'UNAVAILABLE' };
    const current = asOperation(operationData);
    const seenNonce = asNonce(nonceData);

    if (current && sameIdentity(current, input)) {
      this.rememberNonce(tx, nonce, seenNonce, input);
      if (isOperationExpired(new Date(current.issuedAt), input.now)) {
        return { status: 'EXPIRED' };
      }
      return { status: 'ALREADY_RESERVED', fence: current.fence };
    }
    if (current) {
      this.rememberNonce(tx, nonce, seenNonce, input);
      return { status: 'CONFLICT' };
    }
    if (seenNonce) return { status: 'REPLAY' };
    if (
      isOperationExpired(new Date(input.issuedAt), input.now) ||
      input.now.getTime() >
        nonceSchedule(input.receivedAt).logicalExpiresAt.getTime()
    ) {
      this.rememberNonce(tx, nonce, null, input);
      return { status: 'EXPIRED' };
    }

    const reserved = quotaData ? integerField(quotaData, 'reservedPages') : 0;
    if (reserved == null || reserved + input.pageCount > input.limit) {
      if (reserved == null) return { status: 'UNAVAILABLE' };
      this.rememberNonce(tx, nonce, null, input);
      return { status: 'QUOTA' };
    }

    const schedule = operationSchedule(new Date(input.issuedAt));
    const fence = 1;
    this.write(
      tx,
      operation,
      {
        state: 'PLANNED',
        issuedAt: input.issuedAt,
        digest: input.digest,
        mime: input.mime,
        byteLength: input.byteLength,
        pageCount: input.pageCount,
        reservedPages: input.pageCount,
        utcDay: utcDay(input.now),
        fence,
        leaseExpiresAt: new Date(
          input.now.getTime() + (input.leaseMs ?? DEFAULT_LEASE_MS),
        ).toISOString(),
        logicalExpiresAt: schedule.logicalExpiresAt.toISOString(),
        purgeEligibleAt: schedule.purgeEligibleAt.toISOString(),
        receivedAt: input.receivedAt.toISOString(),
      },
      operationPurgeThreshold(input.issuedAt),
    );
    const day = utcDay(input.now);
    const purgeAt = quotaData?.purgeEligibleAt;
    const quotaPurge =
      typeof purgeAt === 'string'
        ? purgeAt
        : quotaPurgeEligibleAt(day).toISOString();
    // expireAt se deriva del purgeEligibleAt que se escribe ahora (no del
    // valor previo si no era texto), con el mismo max(guardado, calculado)
    // que usa purgeIfEligible.
    this.write(
      tx,
      quota,
      {
        utcDay: day,
        reservedPages: reserved + input.pageCount,
        purgeEligibleAt: quotaPurge,
      },
      quotaPurgeThreshold(day, { purgeEligibleAt: quotaPurge }),
    );
    this.rememberNonce(tx, nonce, null, input);
    return { status: 'ADMITTED', fence };
  }

  async confirmCalling(
    input: ConfirmCallingInput,
  ): Promise<ConfirmCallingResult> {
    if (
      !validTarget(input.environment, input.operationId) ||
      !validDate(input.now)
    ) {
      return { status: 'INVALID_CONTRACT' };
    }
    if (!Number.isSafeInteger(input.fence) || input.fence < 1) {
      return { status: 'INVALID_CONTRACT' };
    }
    const attemptId = randomUUID();
    const ref = this.doc('operations', input.environment, input.operationId);
    try {
      const result = await this.db.runTransaction(async (tx) => {
        this.beginAttempt(tx);
        const current = asOperation(await this.read(tx, ref));
        if (
          !current ||
          current.state !== 'PLANNED' ||
          current.fence !== input.fence
        ) {
          return { status: 'LOST_FENCE' as const };
        }
        if (isOperationExpired(new Date(current.issuedAt), input.now)) {
          return { status: 'EXPIRED' as const };
        }
        this.write(
          tx,
          ref,
          { ...current, state: 'CALLING', attemptId },
          operationPurgeThreshold(current.issuedAt),
        );
        return { status: 'CONFIRMED' as const, fence: input.fence, attemptId };
      });
      return await this.observe(
        'confirmCalling',
        result,
        () => this.rereadCalling(ref, input.fence, attemptId),
        { status: 'UNCERTAIN' },
      );
    } catch {
      return this.rereadCalling(ref, input.fence, attemptId);
    }
  }

  async recoverPlanned(input: RecoverInput): Promise<RecoverResult> {
    if (
      !validTarget(input.environment, input.operationId) ||
      !validDate(input.now)
    ) {
      return { status: 'INVALID_CONTRACT' };
    }
    const ref = this.doc('operations', input.environment, input.operationId);
    try {
      const result = await this.db.runTransaction(async (tx) => {
        this.beginAttempt(tx);
        const current = asOperation(await this.read(tx, ref));
        if (!current || current.state !== 'PLANNED')
          return { status: 'NOT_RECOVERABLE' as const };
        if (isOperationExpired(new Date(current.issuedAt), input.now)) {
          return { status: 'NOT_RECOVERABLE' as const };
        }
        const leaseEnds = Date.parse(current.leaseExpiresAt);
        if (!Number.isFinite(leaseEnds) || input.now.getTime() <= leaseEnds) {
          return { status: 'NOT_RECOVERABLE' as const };
        }
        const fence = current.fence + 1;
        this.write(
          tx,
          ref,
          {
            ...current,
            fence,
            leaseExpiresAt: new Date(
              input.now.getTime() + DEFAULT_LEASE_MS,
            ).toISOString(),
          },
          operationPurgeThreshold(current.issuedAt),
        );
        return { status: 'RECOVERED' as const, fence };
      });
      return await this.observe(
        'recover',
        result,
        () => this.rereadRecover(ref),
        {
          status: 'UNCERTAIN',
        },
      );
    } catch {
      return this.rereadRecover(ref);
    }
  }

  async recordComplete(input: RecordInput): Promise<RecordResult> {
    return this.recordTerminal(input, 'COMPLETE', 'complete');
  }

  async recordUnknown(input: RecordInput): Promise<RecordResult> {
    return this.recordTerminal(input, 'UNKNOWN', 'unknown');
  }

  async reservedPages(environment: string, day: string): Promise<number> {
    const snap = await this.doc('quota', environment, day).get();
    if (!snap.exists) return 0;
    const value = snap.get('reservedPages');
    return typeof value === 'number' && Number.isSafeInteger(value) ? value : 0;
  }

  async readDocument(
    kind: CollectionName,
    environment: string,
    id: string,
  ): Promise<Record<string, unknown> | null> {
    const snap = await this.doc(kind, environment, id).get();
    if (!snap.exists) return null;
    return { ...(snap.data() ?? {}) };
  }

  async purgeIfEligible(input: PurgeInput): Promise<{ deleted: number }> {
    if (!ENV_PATTERN.test(input.environment) || !validDate(input.now)) {
      throw new OcrContractError('INVALID_CONTRACT');
    }
    let deleted = 0;
    for (const operationId of input.operationIds) {
      if (!OPERATION_PATTERN.test(operationId)) continue;
      deleted += await this.deleteIfDue(
        this.doc('operations', input.environment, operationId),
        input.now,
        (data) => operationPurgeThreshold(String(data.issuedAt)),
      );
    }
    for (const nonce of input.nonces) {
      if (!NONCE_PATTERN.test(nonce)) continue;
      deleted += await this.deleteIfDue(
        this.doc('nonces', input.environment, nonce),
        input.now,
        (data) => nonceRetainThreshold(data),
      );
    }
    for (const day of input.quotaDays) {
      if (!DAY_PATTERN.test(day)) continue;
      deleted += await this.deleteIfDue(
        this.doc('quota', input.environment, day),
        input.now,
        (data) => quotaPurgeThreshold(day, data),
      );
    }
    return { deleted };
  }

  private async recordTerminal(
    input: RecordInput,
    state: 'COMPLETE' | 'UNKNOWN',
    kind: HookKind,
  ): Promise<RecordResult> {
    if (
      !validTarget(input.environment, input.operationId) ||
      !ATTEMPT_PATTERN.test(input.attemptId) ||
      !validDate(input.now)
    ) {
      return { status: 'INVALID_CONTRACT' };
    }
    const ref = this.doc('operations', input.environment, input.operationId);
    try {
      const result = await this.db.runTransaction(async (tx) => {
        this.beginAttempt(tx);
        const current = asOperation(await this.read(tx, ref));
        if (!current) return { status: 'LOST_FENCE' as const };
        if (current.state === state && current.attemptId === input.attemptId) {
          return { status: 'RECORDED' as const };
        }
        if (
          current.state !== 'CALLING' ||
          current.attemptId !== input.attemptId
        ) {
          return { status: 'LOST_FENCE' as const };
        }
        if (isOperationExpired(new Date(current.issuedAt), input.now)) {
          return { status: 'LOST_FENCE' as const };
        }
        this.write(
          tx,
          ref,
          { ...current, state },
          operationPurgeThreshold(current.issuedAt),
        );
        return { status: 'RECORDED' as const };
      });
      return await this.observe(
        kind,
        result,
        () => this.rereadTerminal(ref, input.attemptId, state),
        {
          status: 'UNCERTAIN',
        },
      );
    } catch {
      return this.rereadTerminal(ref, input.attemptId, state);
    }
  }

  private async observe<T extends { status: string }>(
    kind: HookKind,
    result: T,
    reread: () => Promise<T>,
    uncertain: T,
  ): Promise<T> {
    try {
      this.hooks.afterCommit?.(kind);
      return result;
    } catch {
      if (this.hooks.failReread) return uncertain;
      try {
        return await reread();
      } catch {
        return uncertain;
      }
    }
  }

  private async rereadAdmit(input: AdmitInput): Promise<AdmitResult> {
    if (this.hooks.failReread) return { status: 'UNAVAILABLE' };
    try {
      const snap = await this.doc(
        'operations',
        input.environment,
        input.operationId,
      ).get();
      if (!snap.exists) return { status: 'UNAVAILABLE' };
      const current = asOperation(normalize(snap.data() ?? {}));
      if (!current || !sameIdentity(current, input))
        return { status: 'UNAVAILABLE' };
      if (isOperationExpired(new Date(current.issuedAt), input.now))
        return { status: 'EXPIRED' };
      return { status: 'ALREADY_RESERVED', fence: current.fence };
    } catch {
      return { status: 'UNAVAILABLE' };
    }
  }

  private async rereadCalling(
    ref: DocumentReference,
    fence: number,
    attemptId: string,
  ): Promise<ConfirmCallingResult> {
    if (this.hooks.failReread) return { status: 'UNCERTAIN' };
    try {
      const snap = await ref.get();
      if (!snap.exists) return { status: 'UNAVAILABLE' };
      const current = asOperation(normalize(snap.data() ?? {}));
      if (current?.state === 'CALLING' && current.attemptId === attemptId) {
        return { status: 'CONFIRMED', fence, attemptId };
      }
      if (current?.state === 'PLANNED' && current.fence === fence)
        return { status: 'UNAVAILABLE' };
      return { status: 'LOST_FENCE' };
    } catch {
      return { status: 'UNCERTAIN' };
    }
  }

  private async rereadRecover(ref: DocumentReference): Promise<RecoverResult> {
    if (this.hooks.failReread) return { status: 'UNCERTAIN' };
    try {
      const snap = await ref.get();
      const current = snap.exists
        ? asOperation(normalize(snap.data() ?? {}))
        : null;
      if (current?.state === 'PLANNED')
        return { status: 'RECOVERED', fence: current.fence };
      return { status: 'UNAVAILABLE' };
    } catch {
      return { status: 'UNCERTAIN' };
    }
  }

  private async rereadTerminal(
    ref: DocumentReference,
    attemptId: string,
    state: 'COMPLETE' | 'UNKNOWN',
  ): Promise<RecordResult> {
    if (this.hooks.failReread) return { status: 'UNCERTAIN' };
    try {
      const snap = await ref.get();
      const current = snap.exists
        ? asOperation(normalize(snap.data() ?? {}))
        : null;
      if (current?.state === state && current.attemptId === attemptId)
        return { status: 'RECORDED' };
      if (current?.state === 'CALLING' && current.attemptId === attemptId) {
        return { status: 'UNAVAILABLE' };
      }
      return { status: 'LOST_FENCE' };
    } catch {
      return { status: 'UNCERTAIN' };
    }
  }

  private async deleteIfDue(
    ref: DocumentReference,
    now: Date,
    thresholdFor: (data: DocData) => Date | null,
  ): Promise<number> {
    const snap = await ref.get();
    if (!snap.exists) return 0;
    const data = normalize(snap.data() ?? {});
    if (!data) return 0;
    const threshold = thresholdFor(data);
    if (!threshold || !isPurgeEligible(threshold, now)) return 0;
    await ref.delete();
    return 1;
  }

  private rememberNonce(
    tx: Transaction,
    ref: DocumentReference,
    existing: { operationId: string } | null,
    input: AdmitInput,
  ): void {
    if (existing) return;
    const schedule = nonceSchedule(input.receivedAt);
    const data: DocData = {
      operationId: input.operationId,
      receivedAt: input.receivedAt.toISOString(),
      logicalExpiresAt: schedule.logicalExpiresAt.toISOString(),
      retainUntil: schedule.retainUntil.toISOString(),
      requestTimestamp: input.requestTimestamp,
    };
    this.write(tx, ref, data, nonceRetainThreshold(data));
  }

  private async read(
    tx: Transaction,
    ref: DocumentReference,
  ): Promise<DocData | null> {
    const cache = this.cache(tx);
    const hit = cache.get(ref.path);
    if (hit !== undefined) return hit ? { ...hit } : null;
    const snap = await tx.get(ref);
    const data = snap.exists ? normalize(snap.data() ?? {}) : null;
    cache.set(ref.path, data);
    return data ? { ...data } : null;
  }

  // `expireAt` es solo para la política TTL de Firestore (borrado físico). Se
  // escribe como Date (el SDK lo guarda como Timestamp) y NUNCA entra al cache
  // ni a `normalize`/`asOperation`/`asNonce`: ninguna decisión lógica lo lee.
  // Siempre coincide con el umbral de purga lógica del mismo documento, así
  // que una reescritura reproduce el mismo instante y no puede acortarlo.
  private write(
    tx: Transaction,
    ref: DocumentReference,
    data: DocData,
    expireAt: Date | null,
  ): void {
    if (!expireAt || !Number.isFinite(expireAt.getTime())) {
      throw new OcrContractError('INVALID_CONTRACT');
    }
    const stored = { ...data };
    this.cache(tx).set(ref.path, stored);
    tx.set(ref, { ...stored, expireAt });
  }

  private beginAttempt(tx: Transaction): void {
    const batch = (tx as unknown as { _writeBatch?: { isEmpty?: boolean } })
      ._writeBatch;
    if (!batch || batch.isEmpty) this.overlays.delete(tx);
  }

  private cache(tx: Transaction): Map<string, DocData | null> {
    const existing = this.overlays.get(tx);
    if (existing) return existing;
    const created = new Map<string, DocData | null>();
    this.overlays.set(tx, created);
    return created;
  }

  private doc(
    kind: CollectionName,
    environment: string,
    id: string,
  ): DocumentReference {
    return this.db.doc(`ocrLedgers/${environment}/${kind}/${id}`);
  }

  private invalidAdmit(input: AdmitInput): boolean {
    if (
      !ENV_PATTERN.test(input.environment) ||
      !OPERATION_PATTERN.test(input.operationId)
    ) {
      return true;
    }
    if (!NONCE_PATTERN.test(input.nonce) || !DIGEST_PATTERN.test(input.digest))
      return true;
    if (!MIME_TYPES.has(input.mime) || !canonicalIssuedAt(input.issuedAt))
      return true;
    if (!validDate(input.now) || !validDate(input.receivedAt)) return true;
    if (
      !Number.isSafeInteger(input.byteLength) ||
      input.byteLength < 1 ||
      input.byteLength > OCR_BODY_MAX_BYTES
    ) {
      return true;
    }
    if (
      !Number.isSafeInteger(input.pageCount) ||
      input.pageCount < 1 ||
      input.pageCount > OCR_PAGE_COUNT_MAX
    ) {
      return true;
    }
    if (
      !Number.isSafeInteger(input.requestTimestamp) ||
      input.requestTimestamp < 0
    ) {
      return true;
    }
    if (
      input.leaseMs !== undefined &&
      (!Number.isSafeInteger(input.leaseMs) ||
        input.leaseMs < 1 ||
        input.leaseMs > MAX_LEASE_MS)
    ) {
      return true;
    }
    try {
      resolveDailyPageLimit(input.limit);
    } catch (error) {
      if (error instanceof OcrContractError) return true;
      throw error;
    }
    return false;
  }
}

function validTarget(environment: string, operationId: string): boolean {
  return ENV_PATTERN.test(environment) && OPERATION_PATTERN.test(operationId);
}

function validDate(value: Date): boolean {
  return value instanceof Date && Number.isFinite(value.getTime());
}

function canonicalIssuedAt(value: string): boolean {
  if (!ISSUED_AT_PATTERN.test(value)) return false;
  const parsed = new Date(value);
  return Number.isFinite(parsed.getTime()) && parsed.toISOString() === value;
}

function sameIdentity(current: OperationDoc, input: AdmitInput): boolean {
  return (
    current.digest === input.digest &&
    current.mime === input.mime &&
    current.byteLength === input.byteLength &&
    current.issuedAt === input.issuedAt &&
    current.pageCount === input.pageCount
  );
}

function integerField(data: DocData, key: string): number | null {
  const value = data[key];
  return typeof value === 'number' && Number.isSafeInteger(value) && value >= 0
    ? value
    : null;
}

function asOperation(data: DocData | null): OperationDoc | null {
  if (!data) return null;
  const state = data.state;
  const issuedAt = data.issuedAt;
  const fence = data.fence;
  const byteLength = data.byteLength;
  const pageCount = data.pageCount;
  const reservedPages = data.reservedPages;
  if (typeof state !== 'string' || !STATES.has(state)) return null;
  if (typeof issuedAt !== 'string' || !canonicalIssuedAt(issuedAt)) return null;
  if (typeof data.digest !== 'string' || typeof data.mime !== 'string')
    return null;
  if (
    typeof data.utcDay !== 'string' ||
    typeof data.leaseExpiresAt !== 'string'
  )
    return null;
  if (
    typeof data.logicalExpiresAt !== 'string' ||
    typeof data.purgeEligibleAt !== 'string'
  ) {
    return null;
  }
  if (typeof data.receivedAt !== 'string') return null;
  if (
    typeof fence !== 'number' ||
    typeof byteLength !== 'number' ||
    typeof pageCount !== 'number' ||
    typeof reservedPages !== 'number'
  ) {
    return null;
  }
  const attemptId = data.attemptId;
  if (attemptId !== undefined && typeof attemptId !== 'string') return null;
  return {
    state: state as OperationDoc['state'],
    issuedAt,
    digest: data.digest,
    mime: data.mime,
    byteLength,
    pageCount,
    reservedPages,
    utcDay: data.utcDay,
    fence,
    leaseExpiresAt: data.leaseExpiresAt,
    logicalExpiresAt: data.logicalExpiresAt,
    purgeEligibleAt: data.purgeEligibleAt,
    receivedAt: data.receivedAt,
    ...(typeof attemptId === 'string' ? { attemptId } : {}),
  };
}

function asNonce(data: DocData | null): { operationId: string } | null {
  if (!data || typeof data.operationId !== 'string') return null;
  return { operationId: data.operationId };
}

// Umbral de purga lógica de una operación: issuedAt + 8 días (diseño §6).
// Fuente única para `purgeIfEligible` y para `expireAt`.
function operationPurgeThreshold(issuedAtText: string): Date | null {
  const issuedAt = new Date(issuedAtText);
  if (!Number.isFinite(issuedAt.getTime())) return null;
  return operationSchedule(issuedAt).purgeEligibleAt;
}

// Cuota diaria UTC: el mayor entre la fecha guardada y día + 1 + 8 días
// (diseño §6: el contador es purgable desde los ocho días). Fuente única.
function quotaPurgeThreshold(day: string, data: DocData | null): Date {
  const computed = quotaPurgeEligibleAt(day);
  const stored = new Date(String(data?.purgeEligibleAt));
  if (!Number.isFinite(stored.getTime())) return computed;
  return new Date(Math.max(stored.getTime(), computed.getTime()));
}

// Nonce: receivedAt + 240 s (vencimiento lógico) + 300 s de retención.
// Fuente única para `purgeIfEligible` y para `expireAt`.
function nonceRetainThreshold(data: DocData): Date | null {
  const receivedAt = new Date(String(data.receivedAt));
  if (!Number.isFinite(receivedAt.getTime())) return null;
  const computed = nonceSchedule(receivedAt).retainUntil.getTime();
  const stored = new Date(String(data.retainUntil)).getTime();
  return new Date(
    Math.max(computed, Number.isFinite(stored) ? stored : computed),
  );
}

function normalize(raw: Record<string, unknown>): DocData | null {
  const data: DocData = {};
  for (const [key, value] of Object.entries(raw)) {
    if (
      typeof value === 'string' ||
      (typeof value === 'number' && Number.isFinite(value))
    ) {
      data[key] = value;
    }
  }
  return data;
}
