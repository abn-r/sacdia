// Independent P4-4 acceptance with real service/PostgreSQL; auth and eligibility are fixture seams.
// Exit 0 validates stale rejection, safe reuse, and BOTH ordered concurrency cases.
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const root = path.resolve(__dirname, '../../../sacdia-backend');
const req = createRequire(root + '/package.json');
const { PrismaClient } = req('@prisma/client');
const { PrismaPg } = req('@prisma/adapter-pg');
const { Pool } = req('pg');
const { InvestitureAuthorizationRequestService: Service } = req(root + '/src/investiture-requests/investiture-authorization-requests.service.ts');
const url = new URL(process.env.SACDIA_TEST_DATABASE_URL || 'invalid:');
assert.equal(url.hostname, '127.0.0.1');
assert.equal(url.pathname, '/sacdia_p44_review_test');
assert.equal(url.username, 'codex_p44_review');
const pool = new Pool({ connectionString: url.toString(), max: 6 });
const db = new PrismaClient({ adapter: new PrismaPg(pool) });
const U = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const V = '92929292-9292-4292-8292-929292929292';
const actor = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const now = new Date('2026-10-15T18:00:00Z');
const service = new Service(db, { calculateForEnrollment: async () => ({ investiture_eligibility: { eligible: true } }) });
(async () => {
  await db.investiture_authorization_people.deleteMany();
  await db.investiture_authorization_requests.deleteMany();
  const e = await db.enrollments.findFirst({ where: { user_id: U }, include: { ecclesiastical_year: true } });
  const a = await db.club_role_assignments.findFirst({ where: { user_id: U, status: 'active' } });
  assert(e && a);
  const section = a.club_section_id, year = a.ecclesiastical_year_id;
  const auth = { grants: { global_roles: [], club_assignments: [{ role_name: 'director', operational: true, status: 'active', ecclesiastical_year_id: year, section: { club_section_id: section } }] } };
  await db.users.create({ data: { user_id: V, email: 'reuse-p4@p4.test', name: 'Otro', active: true } });
  await db.club_role_assignments.create({ data: { user_id: V, role_id: a.role_id, ecclesiastical_year_id: year, start_date: e.ecclesiastical_year.start_date, status: 'active', active: true, club_section_id: section } });
  const second = await db.enrollments.create({ data: { user_id: V, class_id: e.class_id, ecclesiastical_year_id: year, investiture_status: 'IN_PROGRESS', record_kind: 'OPERATIONAL', active: true } });
  const present = id => service.present(auth, actor, section, year, '2026-11-01', [id], now);
  const A = await present(e.enrollment_id);
  await service.remove(auth, actor, A.request_id, A.people[0].person_id, now);
  assert.equal(await service.list(auth, section, year), null);
  const B = await present(second.enrollment_id);
  assert.notEqual(A.request_id, B.request_id);
  await assert.rejects(service.addPeople(auth, actor, A.request_id, '2026-11-15', [e.enrollment_id], now), err => err.code === 'INVESTITURE_REQUEST_STALE' && err.getStatus() === 409);
  const pending = await db.investiture_authorization_people.findMany({ where: { status: 'PENDING' } });
  assert.equal(pending.length, 1); assert.equal(pending[0].request_id, B.request_id); assert.equal(pending[0].user_id, V);
  assert.equal((await service.list(auth, section, year)).request_id, B.request_id);
  assert.equal((await db.investiture_authorization_people.findUnique({ where: { person_id: A.people[0].person_id } })).status, 'REMOVED');
  const output = [{ scenario: 'A empty, B active: addPeople(A)', status: 409, code: 'INVESTITURE_REQUEST_STALE', activeGroups: 1, visiblePending: 1, historicalRowPreserved: true }];
  await service.remove(auth, actor, B.request_id, B.people[0].person_id, now);
  const reused = await service.addPeople(auth, actor, A.request_id, '2026-11-15', [e.enrollment_id], now);
  assert.equal(reused.request_id, A.request_id);
  assert.equal(reused.people.filter(p => p.status === 'PENDING').length, 1);
  output.push({ scenario: 'No active group: reuse A', success: true, historicalRowPreserved: reused.people.some(p => p.status === 'REMOVED') });
  const { INVESTITURE_REQUEST_SECTION_LOCK_PREFIX: prefix } = req(root + '/src/investiture-requests/investiture-request-lock.ts');
  async function waiters(count) {
    const until = Date.now() + 3000;
    while (Date.now() < until) {
      const r = await pool.query("SELECT count(*)::int AS n FROM pg_locks WHERE locktype='advisory' AND NOT granted");
      if (r.rows[0].n >= count) return;
      await new Promise(r => setTimeout(r, 10));
    }
    throw new Error('Missing real advisory waiters');
  }
  for (const first of ['present', 'add']) {
    await db.investiture_authorization_people.deleteMany();
    await db.investiture_authorization_requests.deleteMany();
    const old = await present(e.enrollment_id);
    await service.remove(auth, actor, old.request_id, old.people[0].person_id, now);
    const holder = await pool.connect();
    const jobs = [];
    let released = false;
    try {
      await holder.query('BEGIN');
      await holder.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [prefix + section + ':' + year]);
      const start = kind => {
        const promise = kind === 'present' ? present(second.enrollment_id) : service.addPeople(auth, actor, old.request_id, '2026-11-15', [e.enrollment_id], now);
        promise.catch(() => undefined); jobs.push(promise);
      };
      start(first); await waiters(1);
      start(first === 'present' ? 'add' : 'present'); await waiters(2);
      await holder.query('COMMIT'); released = true; holder.release();
      const results = await Promise.allSettled(jobs);
      assert.equal(results[0].status, 'fulfilled');
      if (first === 'present') {
        assert.equal(results[1].status, 'rejected'); assert.equal(results[1].reason.code, 'INVESTITURE_REQUEST_STALE');
      } else {
        assert.equal(results[1].status, 'fulfilled'); assert.equal(results[0].value.request_id, results[1].value.request_id);
      }
      const all = await db.investiture_authorization_people.findMany({ where: { status: 'PENDING' } });
      const visible = (await service.list(auth, section, year)).people.filter(p => p.status === 'PENDING');
      assert.equal(new Set(all.map(p => p.request_id)).size, 1);
      assert.equal(all.length, first === 'present' ? 1 : 2);
      assert.deepEqual(visible.map(p => p.user_id).sort(), all.map(p => p.user_id).sort());
      output.push({ scenario: 'Concurrent, first=' + first, observedAdvisoryWaiters: 2, activeGroups: 1, pendingPeople: all.length, visiblePending: visible.length });
    } finally {
      if (!released) { await holder.query('ROLLBACK'); holder.release(); }
      await Promise.allSettled(jobs);
    }
  }
  console.log(JSON.stringify({ accepted: output, limits: 'Real PostgreSQL/service, supplied auth and mocked eligibility; no HTTP/auth/UI/production/migration deployment.' }, null, 2));
})().catch(e => { console.error(String(e).replace(/postgres(?:ql)?:\/\/\S+/gi, '[redacted]')); process.exitCode = 1; }).finally(async () => { await db.$disconnect(); await pool.end(); });
