import { Buffer } from 'node:buffer';

const VISION_RPC_BUDGET_MS = 25_000;

export type VisionClientConfig = {
  apiEndpoint: 'us-vision.googleapis.com';
  fallback: false;
  'grpc.max_send_message_length': number;
  'grpc.max_receive_message_length': number;
};

export type VisionCallOptions = {
  timeout: number;
  retry: { retryCodes: number[] };
};

export type VisionPage = {
  pageNumber: number | null;
  text: string;
  errorCode: number | null;
};

export type VisionReadResult = {
  pages: VisionPage[];
  totalPages: number | null;
  fileErrorCode: number | null;
};

export type VisionReadInput = {
  mime: string;
  content: Uint8Array;
  pageCount: number;
  remainingMs: number;
};

export type VisionAnnotator = {
  batchAnnotateImages(
    request: unknown,
    options: VisionCallOptions,
  ): Promise<unknown>;
  batchAnnotateFiles(
    request: unknown,
    options: VisionCallOptions,
  ): Promise<unknown>;
  close(): void | Promise<void>;
};

export type VisionClientConstructor = new (
  config: VisionClientConfig,
) => VisionAnnotator;

export type VisionTextReader = {
  read(input: VisionReadInput): Promise<VisionReadResult>;
  close(): Promise<void>;
};

export function visionClientConfig(): VisionClientConfig {
  return {
    apiEndpoint: 'us-vision.googleapis.com',
    fallback: false,
    'grpc.max_send_message_length': 12 * 1024 * 1024,
    'grpc.max_receive_message_length': 16 * 1024 * 1024,
  };
}

export function visionCallOptions(remainingMs: number): VisionCallOptions {
  const remaining = Number.isFinite(remainingMs) ? Math.floor(remainingMs) : 0;
  return {
    timeout: Math.min(VISION_RPC_BUDGET_MS, Math.max(0, remaining)),
    retry: { retryCodes: [] },
  };
}

export function createVisionTextReader(
  options: { Client?: VisionClientConstructor } = {},
): VisionTextReader {
  let opening: Promise<VisionAnnotator> | undefined;

  function client(): Promise<VisionAnnotator> {
    if (!opening) opening = openClient(options.Client);
    return opening;
  }

  async function openClient(
    Client?: VisionClientConstructor,
  ): Promise<VisionAnnotator> {
    try {
      const Factory = Client ?? (await loadDefaultVisionClient());
      return new Factory(visionClientConfig());
    } catch (error) {
      opening = undefined;
      throw error;
    }
  }

  return {
    async read(input) {
      const annotator = await client();
      const call = visionCallOptions(input.remainingMs);
      if (input.mime === 'application/pdf') {
        const pages = Array.from(
          { length: input.pageCount },
          (_, index) => index + 1,
        );
        return mapFile(
          await annotator.batchAnnotateFiles(
            {
              requests: [
                {
                  inputConfig: {
                    content: Buffer.from(input.content),
                    mimeType: 'application/pdf',
                  },
                  features: [{ type: 'DOCUMENT_TEXT_DETECTION' }],
                  imageContext: { languageHints: ['es'] },
                  pages,
                },
              ],
            },
            call,
          ),
        );
      }
      return mapImage(
        await annotator.batchAnnotateImages(
          {
            requests: [
              {
                image: { content: Buffer.from(input.content) },
                features: [{ type: 'DOCUMENT_TEXT_DETECTION' }],
                imageContext: { languageHints: ['es'] },
              },
            ],
          },
          call,
        ),
      );
    },
    async close() {
      const current = opening;
      opening = undefined;
      if (!current) return;
      const annotator = await current.catch(() => undefined);
      await annotator?.close();
    },
  };
}

async function loadDefaultVisionClient(): Promise<VisionClientConstructor> {
  const sdk = (await import('@google-cloud/vision')) as {
    ImageAnnotatorClient: VisionClientConstructor;
  };
  return sdk.ImageAnnotatorClient;
}

function mapImage(result: unknown): VisionReadResult {
  const batch = unwrap(result);
  const responses = Array.isArray(batch?.responses) ? batch.responses : [];
  if (responses.length !== 1) {
    return { pages: [], totalPages: null, fileErrorCode: 1 };
  }
  const page = asRecord(responses[0]);
  if (!page) return { pages: [], totalPages: null, fileErrorCode: 1 };
  return {
    pages: [
      {
        pageNumber: 1,
        text: annotationText(page),
        errorCode: numericError(page.error),
      },
    ],
    totalPages: null,
    fileErrorCode: null,
  };
}

function mapFile(result: unknown): VisionReadResult {
  const batch = unwrap(result);
  const files = Array.isArray(batch?.responses) ? batch.responses : [];
  if (files.length !== 1) {
    return { pages: [], totalPages: null, fileErrorCode: 1 };
  }
  const file = asRecord(files[0]);
  if (!file) return { pages: [], totalPages: null, fileErrorCode: 1 };
  const inner = Array.isArray(file.responses) ? file.responses : [];
  return {
    fileErrorCode: numericError(file.error),
    totalPages: informedTotal(file),
    pages: inner.map((item) => {
      const page = asRecord(item);
      if (!page) return { pageNumber: null, text: '', errorCode: 1 };
      return {
        pageNumber: pageNumberOf(page),
        text: annotationText(page),
        errorCode: numericError(page.error),
      };
    }),
  };
}

function informedTotal(file: Record<string, unknown>): number | null {
  if (!('totalPages' in file) || file.totalPages == null) return null;
  return typeof file.totalPages === 'number' &&
    Number.isInteger(file.totalPages)
    ? file.totalPages
    : -1;
}

function annotationText(page: Record<string, unknown>): string {
  const annotation = asRecord(page.fullTextAnnotation);
  return typeof annotation?.text === 'string' ? annotation.text : '';
}

function pageNumberOf(page: Record<string, unknown>): number | null {
  const context = asRecord(page.context);
  const number = context?.pageNumber;
  return typeof number === 'number' && Number.isInteger(number) ? number : null;
}

function numericError(value: unknown): number | null {
  const record = asRecord(value);
  if (!record || record.code == null || record.code === 0) return null;
  return typeof record.code === 'number' && Number.isFinite(record.code)
    ? record.code
    : 1;
}

function unwrap(result: unknown): Record<string, unknown> | null {
  const value = Array.isArray(result) ? result[0] : result;
  return asRecord(value);
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value == null || typeof value !== 'object') return null;
  return value as Record<string, unknown>;
}
