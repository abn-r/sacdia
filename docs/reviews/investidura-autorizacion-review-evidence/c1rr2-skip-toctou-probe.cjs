// C1RR-2 review (review 31, 2026-10-07) probe. No database, no Redis, no network.
// Run from sacdia-backend/:  node ../docs/reviews/investidura-autorizacion-review-evidence/c1rr2-skip-toctou-probe.cjs
//
// Question: skipOpenInvestitureMail (investiture-communications.service.ts:574-592) reads open rows,
// then writes `skipped` per row with `where: { dispatch_id }` only (no status / no-attempt guard).
// If the worker changes the row between the read and the write, what happens?
//  R1) row `sending` without attempt at read; worker records providerAttempt + provider accepts + ack
//      `sent` before the cron's write.  -> does the cron overwrite `sent` with `skipped`?
//  R2) row `queued` without attempt at read; worker records providerAttempt (provider call in flight)
//      before the cron's write.        -> does the row end `skipped` instead of `uncertain`?
//  R3) control: no interleaving, row without attempt -> `skipped`.
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

function openRow(id, status) {
  return {
    dispatch_id: id, kind: 'REMINDER', execution_key: id, recipient_user_id: '00000000-0000-4000-8000-000000000002',
    role: 'pastor', scope_key: 'scope', status, attempts: 1, payload: {},
    lease_until: null, claim_token: null, sent_at: null, last_error: null,
  };
}

const attempt = () => ({ at: new Date().toISOString(), body: JSON.stringify({ to: 'p@example.test', subject: 's', html: 'h', text: 'h' }) });

(async () => {
  process.env.INVESTITURE_EMAIL_ENABLED = 'false';
  process.env.EMAIL_ENABLED = 'true';
  const out = [];
  for (const scenario of ['R1_ack_sent_between_read_and_write', 'R2_attempt_recorded_between_read_and_write', 'R3_control_no_race']) {
    const w = world();
    const row = openRow(`row-${scenario}`, scenario.startsWith('R1') ? 'sending' : 'queued');
    w.dispatches.push(row);
    const table = w.prisma.investiture_message_dispatches;
    const originalFindMany = table.findMany.bind(table);
    const originalUpdateMany = table.updateMany.bind(table);
    const updateWheres = [];
    let first = true;
    table.findMany = async (args) => {
      const result = await originalFindMany(args);
      const snapshot = JSON.parse(JSON.stringify(result));
      if (first && args?.where?.kind) {
        first = false;
        if (scenario.startsWith('R1')) {
          row.payload = { providerAttempt: attempt(), providerMessageId: 'm-1' };
          row.status = 'sent';
          row.sent_at = new Date();
        } else if (scenario.startsWith('R2')) {
          row.payload = { providerAttempt: attempt() };
          row.status = 'sending';
        }
      }
      return snapshot;
    };
    table.updateMany = async (args) => {
      updateWheres.push(args.where);
      return originalUpdateMany(args);
    };
    const service = serviceOf(w.prisma, { sendInvestitureNotice: async () => undefined });
    try {
      await service.deliverPending();
      out.push({ scenario, row_status: row.status, last_error: row.last_error, has_attempt: !!row.payload?.providerAttempt, sent_at: row.sent_at ? 'set' : null, update_where: updateWheres });
    } catch (e) {
      out.push({ scenario, error: e.message, row_status: row.status });
    }
  }
  console.log(JSON.stringify(out, null, 2));
})().catch((e) => { console.error('PROBE ERROR', e?.message); process.exit(1); });
