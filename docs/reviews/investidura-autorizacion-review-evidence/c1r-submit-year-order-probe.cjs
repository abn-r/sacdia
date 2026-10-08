// C-1 residual independent review probe (2026-10-07). Exit 0 = observations recorded.
// Question: C1-H2 moved the year advisory lock into assertClassCertificateHistoricalAge. submit()
// (certificate-bulk-imports.service.ts) calls it once per READY class item, in findMany order
// (no orderBy), so a batch with items of 2026 then 2025 takes adv(2026) then adv(2025).
// Two concurrent submits with opposite item order -> lock-order inversion on global year advisories?
// The interleaving is forced by holding FOR UPDATE on both users rows (the age check does
// SELECT ... FROM users FOR SHARE right after the first year advisory).
// Run ONLY on a throwaway loopback cluster after the investiture PG e2e suite seeded P4.
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const root = path.resolve(__dirname, '../../../sacdia-backend');
const req = createRequire(root + '/package.json');
const { PrismaClient } = req('@prisma/client');
const { PrismaPg } = req('@prisma/adapter-pg');
const pg = req('pg');
const { CertificateBulkImportsService } = req(root + '/src/certificate-bulk-imports/certificate-bulk-imports.service.ts');
const url = new URL(process.env.SACDIA_TEST_DATABASE_URL || 'invalid:');
assert.equal(url.hostname, '127.0.0.1');
assert.ok(url.pathname.endsWith('_test'));
const D = (s) => new Date(`${s}T00:00:00.000Z`);
const U1 = 'd1d1d1d1-d1d1-4d1d-8d1d-d1d1d1d1d1d1';
const U2 = 'd2d2d2d2-d2d2-4d2d-8d2d-d2d2d2d2d2d2';

(async () => {
  const pool = new pg.Pool({ connectionString: url.toString(), max: 10 });
  const db = new PrismaClient({ adapter: new PrismaPg(pool) });
  const svc = new CertificateBulkImportsService(db, {}, null);
  const observer = new pg.Client({ connectionString: url.toString() });
  await observer.connect();
  const deadlocks = async () => (await observer.query('SELECT deadlocks::int AS d FROM pg_stat_database WHERE datname = current_database()')).rows[0].d;
  const rounds = [];
  try {
    for (const [s, e] of [['2025-01-01', '2025-12-31']]) {
      if (!(await db.ecclesiastical_years.findFirst({ where: { start_date: D(s) } }))) await db.ecclesiastical_years.create({ data: { start_date: D(s), end_date: D(e), active: false } });
    }
    const klass = await db.classes.findFirstOrThrow({ where: { asset_code: null, minimum_age: { gte: 0 }, active: true } });
    for (const [id, email] of [[U1, 'c1r-u1@probe.test'], [U2, 'c1r-u2@probe.test']]) {
      await db.users.upsert({ where: { user_id: id }, update: { birthday: D('1990-01-01') }, create: { user_id: id, email, name: email, active: true, approval_status: 'approved', birthday: D('1990-01-01') } });
    }
    async function batch(userId, dates) {
      const b = await db.certificate_bulk_import_batches.create({ data: { user_id: userId, status: 'DRAFT' } });
      await db.certificate_bulk_import_files.create({ data: { batch_id: b.batch_id, file_url: `batches/sealed/${b.batch_id}.jpg`, file_name: 'x.jpg', file_type: 'image/jpeg', uploaded_by_id: userId, upload_status: 'CONFIRMED', object_key: `batches/sealed/${b.batch_id}.jpg`, confirmed_at: new Date() } });
      for (const d of dates) {
        await db.certificate_bulk_import_items.create({ data: { batch_id: b.batch_id, item_type: 'CLASS', class_id: klass.class_id, completed_at: D(d), status: 'READY' } });
      }
      return b.batch_id;
    }
    for (let i = 0; i < 3; i += 1) {
      const b1 = await batch(U1, ['2026-06-01', '2025-06-01']);
      const b2 = await batch(U2, ['2025-06-01', '2026-06-01']);
      const before = await deadlocks();
      const holder = new pg.Client({ connectionString: url.toString() });
      await holder.connect();
      await holder.query('BEGIN');
      await holder.query('SELECT user_id FROM users WHERE user_id IN ($1::uuid, $2::uuid) FOR UPDATE', [U1, U2]);
      const settle = (p) => p.then(() => 'OK', (e) => `ERR ${e?.code ?? ''} ${String(e?.message ?? e).toLowerCase().includes('deadlock') ? 'DEADLOCK' : String(e?.message ?? e).slice(0, 120)}`);
      const s1 = settle(svc.submit(U1, b1));
      const s2 = settle(svc.submit(U2, b2));
      const end = Date.now() + 10000;
      let blocked = 0;
      while (Date.now() < end) {
        blocked = (await observer.query(`SELECT count(*)::int AS c FROM pg_stat_activity WHERE wait_event_type = 'Lock' AND datname = current_database()`)).rows[0].c;
        if (blocked >= 2) break;
        await new Promise((r) => setTimeout(r, 25));
      }
      const held = (await observer.query(`SELECT count(*)::int AS c FROM pg_locks WHERE locktype='advisory' AND granted`)).rows[0].c;
      await holder.query('COMMIT');
      await holder.end();
      const [r1, r2] = await Promise.all([s1, s2]);
      rounds.push({ round: i, blockedOnUsersRows: blocked, advisoryHeldBeforeRelease: held, submit_2026_then_2025: r1, submit_2025_then_2026: r2, deadlocksDelta: (await deadlocks()) - before });
    }
    console.log(JSON.stringify(rounds, null, 2));
  } finally {
    await observer.end();
    await db.$disconnect();
    await pool.end();
  }
})().catch((e) => { console.error('PROBE ERROR', e?.code, e?.message); process.exit(1); });
