// Residual P4-4 reproduction with real service and PostgreSQL; authorization and eligibility are fixture seams.
// Exit 0 confirms the defect. Only run on a freshly created private database after the delivered suite.
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
assert.equal(url.pathname, '/sacdia_p4fix_review_test');
assert.equal(url.username, 'codex_p4fix_review');
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
  // A valid stale request id from the same authorized section, not a cross-scope request.
  await service.addPeople(auth, actor, A.request_id, '2026-11-15', [e.enrollment_id], now);
  const pending = await db.investiture_authorization_people.findMany({ where: { status: 'PENDING' } });
  const groups = new Set(pending.map(p => p.request_id));
  const listed = await service.list(auth, section, year);
  const visiblePending = listed.people.filter(p => p.status === 'PENDING').length;
  assert.equal(pending.length, 2); assert.equal(groups.size, 2); assert.equal(visiblePending, 1);
  console.log(JSON.stringify({ reproduced: 'P4-4 residual: adding to a previously emptied request revives a second active group', allOperationsSucceeded: true, activeGroups: groups.size, pendingPeople: pending.length, visiblePending, concurrencyRequired: false, limits: 'Real PostgreSQL/service; eligibility mocked true, supplied auth snapshot, no HTTP/auth/UI, no production or migration deployment.' }, null, 2));
})().catch(e => { console.error(String(e).replace(/postgres(?:ql)?:\/\/\S+/gi, '[redacted]')); process.exitCode = 1; }).finally(async () => { await db.$disconnect(); await pool.end(); });
