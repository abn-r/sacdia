export type AdmitInput = {
  environment: string;
  operationId: string;
  issuedAt: string;
  digest: string;
  mime: string;
  byteLength: number;
  pageCount: number;
  nonce: string;
  requestTimestamp: number;
  receivedAt: Date;
  now: Date;
  limit: number;
  leaseMs?: number;
};

export type AdmitResult =
  | { status: 'ADMITTED'; fence: number }
  | { status: 'ALREADY_RESERVED'; fence: number }
  | { status: 'REPLAY' }
  | { status: 'CONFLICT' }
  | { status: 'QUOTA' }
  | { status: 'EXPIRED' }
  | { status: 'INVALID_CONTRACT' }
  | { status: 'UNAVAILABLE' };

export type ConfirmCallingInput = {
  environment: string;
  operationId: string;
  fence: number;
  now: Date;
};

export type ConfirmCallingResult =
  | { status: 'CONFIRMED'; fence: number; attemptId: string }
  | { status: 'LOST_FENCE' }
  | { status: 'EXPIRED' }
  | { status: 'UNCERTAIN' }
  | { status: 'UNAVAILABLE' }
  | { status: 'INVALID_CONTRACT' };

export type RecoverInput = {
  environment: string;
  operationId: string;
  now: Date;
};

export type RecoverResult =
  | { status: 'RECOVERED'; fence: number }
  | { status: 'NOT_RECOVERABLE' }
  | { status: 'UNCERTAIN' }
  | { status: 'UNAVAILABLE' }
  | { status: 'INVALID_CONTRACT' };

export type RecordInput = {
  environment: string;
  operationId: string;
  attemptId: string;
  now: Date;
};

export type RecordResult =
  | { status: 'RECORDED' }
  | { status: 'LOST_FENCE' }
  | { status: 'UNCERTAIN' }
  | { status: 'UNAVAILABLE' }
  | { status: 'INVALID_CONTRACT' };

export type PurgeInput = {
  environment: string;
  now: Date;
  operationIds: readonly string[];
  nonces: readonly string[];
  quotaDays: readonly string[];
};

export type OcrLedger = {
  admit(input: AdmitInput): Promise<AdmitResult>;
  confirmCalling(input: ConfirmCallingInput): Promise<ConfirmCallingResult>;
  recoverPlanned(input: RecoverInput): Promise<RecoverResult>;
  recordComplete(input: RecordInput): Promise<RecordResult>;
  recordUnknown(input: RecordInput): Promise<RecordResult>;
};
