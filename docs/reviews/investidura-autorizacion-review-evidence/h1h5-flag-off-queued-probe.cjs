// Independent H1-H5 review probe (2026-10-07). No database, no Redis, no network.
// Run from sacdia-backend/:  node ../docs/reviews/investidura-autorizacion-review-evidence/h1h5-flag-off-queued-probe.cjs
//
// Question (H3 follow-up): skipOpenInvestitureMail marks PRESENTATION/REMINDER rows in
// `queued`/`sending` as `skipped` when INVESTITURE_EMAIL_ENABLED is off. Does the BullMQ
// email processor re-check the flag (or the row) before provider.send?
//  S1: row queued while the flag was on, flag turned off (restart), the queued job runs
//      before any cron tick calls skipOpenInvestitureMail.
//  S2: flag turned off while the processor is between recordProviderAttempt and the
//      provider acknowledgement; a cron tick skips the row in that window.
// Reuses the in-memory world/serviceOf helpers of the delivery spec (read-only import).
const path = require('node:path');
const assert = require('node:assert/strict');
const root = process.cwd();
for (const name of ['describe', 'it', 'test', 'beforeEach', 'afterEach', 'beforeAll', 'afterAll']) {
  global[name] = () => undefined;
}
global.describe.each = () => () => undefined;
global.it.each = () => () => undefined;
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
const { world, serviceOf } = require(path.join(root, 'src/investiture-requests/investiture-communications.delivery.spec.ts'));
const { EmailProcessor } = require(path.join(root, 'src/common/email/email.processor.ts'));
const { EMAIL_JOB_INVESTITURE_NOTICE } = require(path.join(root, 'src/common/email/email.queue.ts'));

const MONDAY = new Date('2026-10-05T16:00:00.000Z');

function setup(onSend) {
  const w = world();
  const queued = [];
  const service = serviceOf(w.prisma, {
    sendInvestitureNotice: async ({ dispatchId }) => {
      queued.push(dispatchId);
    },
  });
  const sent = [];
  const processor = new EmailProcessor(
    {
      send: async (message) => {
        sent.push(message.idempotencyKey);
        if (onSend) await onSend(service);
        return { messageId: `msg-${sent.length}` };
      },
    },
    { get: () => undefined },
    {},
    { get: () => service },
  );
  processor.renderTemplate = async () => ({ subject: 's', html: '<p>x</p>', text: 'x' });
  const run = (dispatchId) =>
    processor.processInvestiture({ name: EMAIL_JOB_INVESTITURE_NOTICE, data: { dispatchId }, attemptsMade: 0 });
  return { w, service, queued, sent, run };
}

async function main() {
  process.env.EMAIL_ENABLED = 'true';
  const results = [];

  // S1
  process.env.INVESTITURE_EMAIL_ENABLED = 'true';
  const s1 = setup();
  const accepted = await s1.service.dispatchReminders(MONDAY);
  assert(accepted > 0 && s1.queued.length > 0, 'reminders must be queued while on');
  process.env.INVESTITURE_EMAIL_ENABLED = 'false';
  const id1 = s1.queued[0];
  await s1.run(id1);
  const row1 = s1.w.dispatches.find((row) => row.dispatch_id === id1);
  results.push({ scenario: 'S1 queued job runs after flag off, before any cron', provider_sends: s1.sent.length, row_status: row1 && row1.status });

  // S2
  process.env.INVESTITURE_EMAIL_ENABLED = 'true';
  const s2 = setup(async (service) => {
    process.env.INVESTITURE_EMAIL_ENABLED = 'false';
    await service.deliverPending(MONDAY); // cron tick while provider call is in flight
  });
  await s2.service.dispatchReminders(MONDAY);
  const id2 = s2.queued[0];
  let firstError = null;
  try {
    await s2.run(id2);
  } catch (error) {
    firstError = error instanceof Error ? error.message : String(error);
  }
  let retryError = null;
  try {
    await s2.run(id2); // BullMQ retry
  } catch (error) {
    retryError = error instanceof Error ? error.message : String(error);
  }
  const row2 = s2.w.dispatches.find((row) => row.dispatch_id === id2);
  results.push({
    scenario: 'S2 flag off + cron skip while provider call in flight',
    provider_sends: s2.sent.length,
    first_attempt_error: firstError,
    retry_error: retryError,
    row_status: row2 && row2.status,
    row_last_error: row2 && row2.last_error,
  });

  console.log(JSON.stringify(results, null, 2));
  const s1Leak = results[0].provider_sends > 0;
  const s2Lie = results[1].provider_sends > 0 && results[1].row_status === 'skipped';
  console.log(`RESULT: S1 ${s1Leak ? 'SENT WITH FLAG OFF' : 'not sent'}; S2 ${s2Lie ? 'SENT BUT ROW SAYS skipped' : 'consistent'}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
