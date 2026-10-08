// C1R-N4 independent re-review probe (2026-10-07). No database, no Redis, no network.
// Run from sacdia-backend/:  node ../docs/reviews/investidura-autorizacion-review-evidence/c1rr-bulk-skip-attempt-probe.cjs
//
// Question: C1R-N4 says `skipped` is only valid when the provider never received the send;
// a row with a recorded providerAttempt must end `uncertain`. The processor now honours that
// (email.processor.ts investitureDeliveryOpen). Does the bulk path deliverPending ->
// skipOpenInvestitureMail (investiture-communications.service.ts) honour it too?
//  A) REMINDER row `queued` with providerAttempt, flag off, deliverPending() runs (cron) first.
//  B) same row, then the queued job is processed afterwards.
//  C) control: processor first (the C1R-N4 unit test path).
// Reuses the in-memory world/serviceOf helpers of the delivery spec (read-only import).
const path = require('node:path');
const root = process.cwd();
for (const name of ['describe', 'it', 'test', 'beforeEach', 'afterEach', 'beforeAll', 'afterAll']) {
  global[name] = () => undefined;
}
global.describe.each = () => () => undefined;
global.it.each = () => () => undefined;
global.expect = () => new Proxy({}, { get: () => () => undefined });
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
const { INVESTITURE_MAIL_GATE } = require(path.join(root, 'src/common/email/investiture-mail.gate.ts'));

function attemptRow(id) {
  return {
    dispatch_id: id, kind: 'REMINDER', execution_key: id, recipient_user_id: '00000000-0000-4000-8000-000000000002',
    role: 'pastor', scope_key: 'scope', status: 'queued', attempts: 1,
    payload: { providerAttempt: { at: new Date().toISOString(), body: JSON.stringify({ to: 'p@example.test', from: 'x', subject: 's', html: '<p>h</p>', text: 'h', idempotencyKey: id }) } },
    lease_until: null, claim_token: null, sent_at: null, last_error: null,
  };
}

function processorFor(service, sends) {
  const provider = { send: async () => { sends.push(1); return { messageId: 'm' }; } };
  const moduleRef = { get: (token) => (token === INVESTITURE_MAIL_GATE ? service : undefined) };
  const config = { get: () => 'SACDIA <noreply@example.test>' };
  const p = new EmailProcessor(provider, config, {}, moduleRef);
  return p;
}

(async () => {
  process.env.INVESTITURE_EMAIL_ENABLED = 'false';
  process.env.EMAIL_ENABLED = 'true';
  const out = [];
  for (const scenario of ['A_cron_only', 'B_cron_then_job', 'C_job_only']) {
    const w = world();
    const row = attemptRow(`attempt-${scenario}`);
    w.dispatches.push(row);
    const sends = [];
    const service = serviceOf(w.prisma, { sendInvestitureNotice: async () => undefined });
    let processor;
    try { processor = processorFor(service, sends); } catch (e) { out.push({ scenario, error: `processor ctor: ${e.message}` }); continue; }
    try {
      if (scenario !== 'C_job_only') await service.deliverPending();
      if (scenario !== 'A_cron_only') {
        await processor.process({ name: EMAIL_JOB_INVESTITURE_NOTICE, id: 'j', data: { dispatchId: row.dispatch_id }, attemptsMade: 0 });
      }
      out.push({ scenario, provider_sends: sends.length, row_status: row.status, last_error: row.last_error });
    } catch (e) {
      out.push({ scenario, error: e.message, row_status: row.status });
    }
  }
  console.log(JSON.stringify(out, null, 2));
})().catch((e) => { console.error('PROBE ERROR', e?.message); process.exit(1); });
