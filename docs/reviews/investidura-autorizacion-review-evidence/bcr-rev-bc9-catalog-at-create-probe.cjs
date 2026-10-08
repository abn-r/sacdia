// BCR review (2026-10-07) probe for BC-9 / BCR-9. No database, no network.
// Run from sacdia-backend/:
//   node ../docs/reviews/investidura-autorizacion-review-evidence/bcr-rev-bc9-catalog-at-create-probe.cjs
//
// Question: BC-9 asked that an item created with mark_as_ready=true and failing "the same
// validation as mark-ready (age, catalog, date)" is born NEEDS_REVIEW with its reason.
// addItem() catches assertCatalogChoice errors and maps them with reviewReason(). The catalog
// check throws Nest BadRequestException('CERTIFICATE_IMPORT_CATALOG_NOT_FOUND'). With Nest 11,
// getResponse() is an object, so reviewReason() returns null and addItem rethrows (400).
const path = require('node:path');
const root = process.cwd();
require(path.join(root, 'node_modules/ts-node')).register({
  transpileOnly: true,
  skipProject: true,
  compilerOptions: {
    module: 'CommonJS', moduleResolution: 'Node', target: 'ES2022', jsx: 'react-jsx',
    experimentalDecorators: true, emitDecoratorMetadata: true, esModuleInterop: true,
    ignoreDeprecations: '6.0',
  },
});
require(path.join(root, 'node_modules/reflect-metadata'));
const { BadRequestException } = require(path.join(root, 'node_modules/@nestjs/common'));
const { CertificateBulkImportsService } = require(
  path.join(root, 'src/certificate-bulk-imports/certificate-bulk-imports.service.ts'),
);

(async () => {
  const service = Object.create(CertificateBulkImportsService.prototype);
  const catalogError = new BadRequestException('CERTIFICATE_IMPORT_CATALOG_NOT_FOUND');
  const created = [];
  const tx = {
    certificate_bulk_import_batches: {
      findFirst: async () => ({ batch_id: 'b1', user_id: 'u1', status: 'DRAFT', revision: 0 }),
      findUnique: async () => ({ batch_id: 'b1', user_id: 'u1', status: 'DRAFT', revision: 0 }),
      update: async () => ({}),
    },
    certificate_bulk_import_items: {
      count: async () => 0,
      create: async ({ data }) => { created.push(data); return { item_id: 'i1', ...data }; },
    },
  };
  service.prisma = { $transaction: async (fn) => fn(tx) };
  service.findOwnedBatch = async () => ({ batch_id: 'b1', user_id: 'u1', status: 'DRAFT', revision: 0 });
  service.assertCatalogChoice = async () => { throw catalogError; };
  service.assertClassAgeIfReady = async () => undefined;
  service.recordEvent = async () => undefined;
  let outcome;
  try {
    const item = await service.addItem('u1', 'b1', {
      item_type: 'HONOR', honor_id: 999999, completed_at: '2020-01-01', mark_as_ready: true,
    });
    outcome = { result: 'created', status: item.status, rejection_reason: item.rejection_reason ?? null };
  } catch (error) {
    outcome = { result: 'thrown', name: error.constructor.name, message: error.message, status: error.getStatus?.() };
  }
  console.log(JSON.stringify({
    nest_getResponse_type: typeof catalogError.getResponse(),
    reviewReason_of_catalog_error: service.reviewReason(catalogError),
    addItem_with_unknown_catalog: outcome,
    items_created: created.length,
  }, null, 2));
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
