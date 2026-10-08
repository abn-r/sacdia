// BC review (2026-10-07) probe for BC-8. No database, no Redis, no network.
// Run from sacdia-backend/:
//   node ../docs/reviews/investidura-autorizacion-review-evidence/bc-reminder-retry-cap-probe.cjs
//
// Question: REMINDER_RETRY_LIMIT (5) is checked against `attempts` in freshMail/reminderRetryDraft.
// recoverRow() re-queues a BullMQ job in state `failed` (retryFailedInvestitureJob) BEFORE any
// freshMail / cap / day check, and that path does not increment `attempts`.
//  Q1) A `queued` REMINDER row whose BullMQ job keeps failing: how many re-queues happen across
//      20 cron runs (every 15 min, same local day)? Does the cap of 5 stop it?
//  Q2) deliverOnce path: a `failed` row reclaimed by deliverOnce. On which claim does prepare()
//      (worker) start skipping with reminder_retry_limit? (off-by-one check)
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
const { reminderRetrySkipReason } = require(path.join(root, 'src/investiture-requests/investiture-communications.rules.ts'));

(async () => {
  process.env.INVESTITURE_EMAIL_ENABLED = 'true';
  process.env.EMAIL_ENABLED = 'true';
  const monday10 = new Date('2026-10-05T16:00:00.000Z'); // 10:00 America/Mexico_City
  const w = world();
  w.dispatches.push({
    dispatch_id: 'bc-q1', kind: 'REMINDER', execution_key: '2026-10-05',
    recipient_user_id: '00000000-0000-4000-8000-0000000000b2', role: 'pastor', scope_key: 'field:10',
    status: 'queued', attempts: 1, payload: { channel: 'email', requestIds: [] },
    lease_until: null, claim_token: null, sent_at: null, last_error: null,
  });
  let requeues = 0;
  const service = serviceOf(w.prisma, {
    sendInvestitureNotice: async () => undefined,
    inspectInvestitureJob: async () => 'failed',
    retryFailedInvestitureJob: async () => { requeues += 1; },
  });
  for (let i = 0; i < 20; i += 1) {
    await service.deliverPending(new Date(monday10.getTime() + i * 15 * 60 * 1000));
  }
  const row = w.dispatches.find((item) => item.dispatch_id === 'bc-q1');
  console.log(JSON.stringify({
    Q1: { cron_runs: 20, bullmq_requeues: requeues, final_status: row.status, final_attempts: row.attempts, last_error: row.last_error },
  }));
  const q2 = [];
  for (let attempts = 1; attempts <= 6; attempts += 1) {
    q2.push({ attempts_after_claim: attempts, prepare_skip_reason: reminderRetrySkipReason({ now: monday10, timeZone: 'America/Mexico_City', executionKey: '2026-10-05', attempts }) });
  }
  console.log(JSON.stringify({ Q2: q2 }));
})().catch((e) => { console.error('PROBE ERROR', e); process.exit(1); });
