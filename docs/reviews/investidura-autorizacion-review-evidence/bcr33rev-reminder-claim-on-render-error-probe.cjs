// BCR33 review (2026-10-07): copy of bcr-rev-reminder-claim-on-render-error-probe adding a
// $executeRaw mock (the BCR33-N2 release DELETE) mirroring delivery.spec. Original: probe for BCR-5. No database, no Redis, no network.
// Run from sacdia-backend/:
//   node ../docs/reviews/investidura-autorizacion-review-evidence/bcr33rev-reminder-claim-on-render-error-probe.cjs
//
// Question: claimDayAndStage() inserts the day claim and then calls dueReminders(). dueReminders()
// catches per-field render errors (onFieldError), e.g. InvestiturePanelUrlMissingError when
// ADMIN_PANEL_URL is missing/invalid. Is the day claim still committed with zero reminders, so
// that after fixing the config later the same day nothing is sent?
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
const { world } = require(path.join(root, 'src/investiture-requests/investiture-communications.delivery.spec.ts'));
const { InvestitureCommunicationsService } = require(
  path.join(root, 'src/investiture-requests/investiture-communications.service.ts'),
);

const at = (day, localHour) =>
  new Date(`${day}T${String(localHour + 6).padStart(2, '0')}:00:00.000Z`);

function serviceWithPanel(prisma, panel) {
  const service = new InvestitureCommunicationsService(
    prisma,
    { sendInvestitureNotice: async () => undefined },
    { pushBestEffort: async () => undefined },
    { get: () => panel },
  );
  service.bindClock(() => at('2026-10-05', 10));
  service.logger = { error: (m) => errors.push(String(m)), warn: () => undefined, log: () => undefined, debug: () => undefined };
  return service;
}
const errors = [];

(async () => {
  process.env.INVESTITURE_EMAIL_ENABLED = 'true';
  process.env.EMAIL_ENABLED = 'true';
  const { prisma, dispatches, ledger } = world();
  const deletes = [];
  prisma.$executeRaw = async (sql) => {
    const [ids, roles, dates] = sql.values;
    let n = 0;
    ids.forEach((id, i) => { const k = `${id}:${roles[i]}:${dates[i]}`; deletes.push(k); if (ledger.delete(k)) n += 1; });
    return n;
  };
  const broken = serviceWithPanel(prisma, '');
  const first = await broken.dispatchReminders(at('2026-10-05', 10));
  const afterBroken = { accepted: first, ledger: [...ledger], reminders: dispatches.filter((r) => r.kind === 'REMINDER').length };
  const fixed = serviceWithPanel(prisma, 'https://admin.example.test');
  const second = await fixed.dispatchReminders(at('2026-10-05', 11));
  const afterFix = { accepted: second, ledger: [...ledger], reminders: dispatches.filter((r) => r.kind === 'REMINDER').length };
  const third = await serviceWithPanel(prisma, "https://admin.example.test").dispatchReminders(at("2026-10-05", 12));
  console.log(JSON.stringify({
    released_keys: deletes,
    run_12_00_again: { accepted: third, reminders: dispatches.filter((r) => r.kind === "REMINDER").length },
    run_10_00_missing_panel_url: afterBroken,
    run_11_00_after_fix: afterFix,
    logged_errors: errors.map((e) => e.replace(/\s+/g, ' ').slice(0, 140)),
    RESULT: afterBroken.ledger.length > 0 || afterFix.reminders === 0
      ? 'day consumed with zero reminders; no recovery after fixing ADMIN_PANEL_URL'
      : 'day not consumed / recovered',
  }, null, 2));
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
