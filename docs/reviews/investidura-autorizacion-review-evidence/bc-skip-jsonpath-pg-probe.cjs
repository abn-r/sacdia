// BC review (2026-10-07) probe. Real PostgreSQL (throwaway cluster), real PrismaClient, real
// InvestitureCommunicationsService. No Redis, no network, no provider.
// Run from sacdia-backend/:
//   BC_PROBE_DATABASE_URL=postgresql://postgres@127.0.0.1:55485/<db>_test \
//   node ../docs/reviews/investidura-autorizacion-review-evidence/bc-skip-jsonpath-pg-probe.cjs
//
// Question: retireOpenInvestitureMail writes `skipped` with
//   NOT: { payload: { path: ['providerAttempt','at'], not: Prisma.DbNull } }
// The unit mock interprets that as "row has no providerAttempt.at". Does real Prisma+PG agree?
//  P1 pending, payload {"channel":"email"} (no attempt)            -> expect skipped
//  P2 queued, payload {}                                            -> expect skipped
//  P3 failed, payload {"providerAttempt":{}} (empty attempt)        -> expect skipped
//  P4 sending, payload with providerAttempt {at, body} (read fresh) -> expect uncertain
//  R1 DB row `sent` with attempt; cron read a stale `sending` row w/o attempt -> expect sent
//  R2 DB row `queued` with attempt.at; cron read a stale `queued` row w/o attempt -> expect uncertain
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
const { PrismaClient } = require(path.join(root, 'node_modules/@prisma/client'));
const { PrismaPg } = require(path.join(root, 'node_modules/@prisma/adapter-pg'));
const pg = require(path.join(root, 'node_modules/pg'));
const { InvestitureCommunicationsService } = require(
  path.join(root, 'src/investiture-requests/investiture-communications.service.ts'),
);

const url = process.env.BC_PROBE_DATABASE_URL;
if (!url || !/_test(\?|$)/.test(url) || !/127\.0\.0\.1|localhost/.test(url)) {
  console.error('BC_PROBE_DATABASE_URL must be a loopback *_test database');
  process.exit(2);
}
const RECIPIENT = '00000000-0000-4000-8000-0000000000b1';
const attempt = () => ({ at: new Date().toISOString(), body: JSON.stringify({ to: 'p@example.test', subject: 's', html: 'h', text: 'h' }) });

(async () => {
  process.env.INVESTITURE_EMAIL_ENABLED = 'false';
  const pool = new pg.Pool({ connectionString: url });
  const prisma = new PrismaClient({ adapter: new PrismaPg(pool), log: [{ emit: 'event', level: 'query' }] });
  const sql = [];
  prisma.$on('query', (e) => { if (/UPDATE/i.test(e.query)) sql.push(e.query); });
  await prisma.investiture_message_dispatches.deleteMany({ where: { recipient_user_id: RECIPIENT } });

  const rows = {
    P1: { status: 'pending', payload: { channel: 'email' } },
    P2: { status: 'queued', payload: {} },
    P3: { status: 'failed', payload: { providerAttempt: {} } },
    P4: { status: 'sending', payload: { channel: 'email', providerAttempt: attempt() } },
    R1: { status: 'sent', payload: { channel: 'email', providerAttempt: attempt() }, stale: { status: 'sending', payload: {} } },
    R2: { status: 'queued', payload: { channel: 'email', providerAttempt: attempt() }, stale: { status: 'queued', payload: {} } },
  };
  const ids = {};
  for (const [name, spec] of Object.entries(rows)) {
    const created = await prisma.investiture_message_dispatches.create({
      data: {
        kind: 'REMINDER', execution_key: `bc-probe-${name}`, recipient_user_id: RECIPIENT,
        role: 'pastor', scope_key: 'bc-probe', status: spec.status, attempts: 1, payload: spec.payload,
        sent_at: spec.status === 'sent' ? new Date() : null,
      },
    });
    ids[name] = created.dispatch_id;
  }
  // Stale read for R1/R2 only: findMany returns what the cron saw before the worker moved the row.
  const delegate = prisma.investiture_message_dispatches;
  const wrappedDelegate = new Proxy(delegate, {
    get(target, prop) {
      if (prop === 'findMany') {
        return async (args) => {
          const found = await target.findMany(args);
          return found
            .filter((row) => row.recipient_user_id === RECIPIENT)
            .map((row) => {
              const name = Object.keys(ids).find((key) => ids[key] === row.dispatch_id);
              const stale = name && rows[name].stale;
              return stale ? { ...row, ...stale } : row;
            });
        };
      }
      const value = target[prop];
      return typeof value === 'function' ? value.bind(target) : value;
    },
  });
  const wrappedPrisma = new Proxy(prisma, {
    get(target, prop) {
      if (prop === 'investiture_message_dispatches') return wrappedDelegate;
      const value = target[prop];
      return typeof value === 'function' ? value.bind(target) : value;
    },
  });
  // R1 must be visible to findMany's status filter; the stale view is applied after the query,
  // so include `sent` rows by temporarily presenting R1 as open in the DB? No: findMany filters by
  // status in SQL. To keep R1 in the read, we inject it explicitly below.
  const service = new InvestitureCommunicationsService(wrappedPrisma, {}, {}, { get: () => undefined });
  const originalFindMany = wrappedDelegate.findMany;
  const injected = new Proxy(wrappedDelegate, {
    get(target, prop) {
      if (prop === 'findMany') {
        return async (args) => {
          const found = await originalFindMany(args);
          if (args?.where?.kind) {
            const r1 = await delegate.findUnique({ where: { dispatch_id: ids.R1 } });
            found.push({ ...r1, ...rows.R1.stale });
          }
          return found;
        };
      }
      return target[prop];
    },
  });
  const finalPrisma = new Proxy(prisma, {
    get(target, prop) {
      if (prop === 'investiture_message_dispatches') return injected;
      const value = target[prop];
      return typeof value === 'function' ? value.bind(target) : value;
    },
  });
  service.prisma = finalPrisma;
  await service.dispatchReminders(new Date());

  const expected = { P1: 'skipped', P2: 'skipped', P3: 'skipped', P4: 'uncertain', R1: 'sent', R2: 'uncertain' };
  let failures = 0;
  for (const [name, id] of Object.entries(ids)) {
    const row = await delegate.findUnique({ where: { dispatch_id: id } });
    const ok = row.status === expected[name];
    if (!ok) failures += 1;
    console.log(`${name}: status=${row.status} expected=${expected[name]} last_error=${row.last_error} ${ok ? 'OK' : 'MISMATCH'}`);
  }
  console.log('--- UPDATE statements (Prisma query log) ---');
  for (const statement of sql) console.log(statement);
  await delegate.deleteMany({ where: { recipient_user_id: RECIPIENT } });
  await prisma.$disconnect();
  await pool.end();
  console.log(failures === 0 ? 'RESULT: all expectations met' : `RESULT: ${failures} mismatch(es)`);
  process.exit(failures === 0 ? 0 : 1);
})().catch((error) => {
  console.error(error);
  process.exit(3);
});
