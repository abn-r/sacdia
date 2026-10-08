// Independent defect reproduction. Real PostgreSQL transactions; eligibility and auth snapshot are fixture seams.
// Run ONLY after the delivered PG suite in a newly created private cluster.
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
assert.equal(url.pathname, '/sacdia_phase4_review_test');
assert.equal(url.username, 'codex_phase4_review');
const pool = new Pool({ connectionString: url.toString(), max: 6 });
const db = new PrismaClient({ adapter: new PrismaPg(pool) });
const U = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const V = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const actor = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const now = new Date('2026-10-15T18:00:00Z');
const eligibility = { calculateForEnrollment: async () => ({ investiture_eligibility: { eligible: true } }) };
const service = new Service(db, eligibility);
const output = [];
function auth(section, year) { return { grants: { global_roles: [], club_assignments: [{ role_name: 'director', operational: true, status: 'active', ecclesiastical_year_id: year, section: { club_section_id: section } }] } }; }
async function code(promise) { try { await promise; return 'SUCCESS'; } catch (e) { if (!e.code) throw e; return e.code; } }
async function clear() { await db.investiture_authorization_people.deleteMany(); await db.investiture_authorization_requests.deleteMany(); }
(async () => {
  const row = await db.enrollments.findFirst({ where: { user_id: U }, include: { classes: true, ecclesiastical_year: true } });
  const assignment = await db.club_role_assignments.findFirst({ where: { user_id: U }, include: { club_sections: true } });
  assert(row && assignment);
  const eid = row.enrollment_id, cid = row.class_id, year = row.ecclesiastical_year_id, section = assignment.club_section_id;
  const present = (s = section, enrollment = eid) => service.present(auth(s, year), actor, s, year, '2026-11-01', [enrollment], now);
  await clear();
  // A genuine two-year GM enrollment remains keyed to its starting year.
  const gmType = await db.club_types.create({ data: { name: 'Guías Mayores', active: true } });
  await db.club_sections.update({ where: { club_section_id: section }, data: { club_type_id: gmType.club_type_id } });
  const previous = await db.ecclesiastical_years.create({ data: { start_date: new Date('2025-01-01Z'), end_date: new Date('2025-12-31Z'), active: false } });
  await db.classes.update({ where: { class_id: cid }, data: { name: 'Guía Mayor P4', club_type_id: gmType.club_type_id, minimum_age: 16, min_duration_years: 2, max_duration_years: 3 } });
  await db.enrollments.update({ where: { enrollment_id: eid }, data: { ecclesiastical_year_id: previous.year_id } });
  const elapsed = await db.ecclesiastical_years.count({ where: { start_date: { gte: previous.start_date, lte: row.ecclesiastical_year.start_date } } });
  assert.equal(elapsed, 2);
  const durationResult = await code(present());
  assert.equal(durationResult, 'INVESTITURE_REQUEST_OUTSIDE_SECTION');
  await db.enrollments.update({ where: { enrollment_id: eid }, data: { ecclesiastical_year_id: year } });
  const currentYearResult = await code(present());
  assert.equal(currentYearResult, 'INVESTITURE_DURATION_MIN_NOT_MET');
  output.push({ case: 'P4-1 duration', elapsed, originalEnrollment: durationResult, ifRelabeledToCurrentYear: currentYearResult });
  await db.classes.update({ where: { class_id: cid }, data: { name: row.classes.name, club_type_id: row.classes.club_type_id, minimum_age: row.classes.minimum_age, min_duration_years: 1, max_duration_years: 1 } });
  await db.club_sections.update({ where: { club_section_id: section }, data: { club_type_id: assignment.club_sections.club_type_id } });
  // GM home membership with a legitimate cross-type CQ enrollment.
  const gm = await db.club_sections.create({ data: { active: true, club_type_id: gmType.club_type_id, main_club_id: assignment.club_sections.main_club_id } });
  const gmClass = await db.classes.create({ data: { name: 'GM P4', active: true, club_type_id: gmType.club_type_id, minimum_age: 16, min_duration_years: 1, max_duration_years: 1 } });
  await db.enrollments.create({ data: { user_id: U, class_id: gmClass.class_id, ecclesiastical_year_id: previous.year_id, investiture_status: 'INVESTIDO', record_kind: 'HISTORICAL_CERTIFICATE', active: true } });
  await db.enrollments.update({ where: { enrollment_id: eid }, data: { cross_type_enrollment: true } });
  await db.club_role_assignments.update({ where: { assignment_id: assignment.assignment_id }, data: { club_section_id: gm.club_section_id } });
  const home = await code(present(gm.club_section_id)), targetType = await code(present());
  assert.equal(home, 'INVESTITURE_REQUEST_OUTSIDE_SECTION'); assert.equal(targetType, 'INVESTITURE_REQUEST_OUTSIDE_SECTION');
  output.push({ case: 'P4-2 cross type GM', homeSection: home, classTypeSection: targetType });
  await db.club_role_assignments.update({ where: { assignment_id: assignment.assignment_id }, data: { club_section_id: section } });
  await db.enrollments.update({ where: { enrollment_id: eid }, data: { cross_type_enrollment: false } });
  // Two distinct users do not share the user advisory lock. Barrier only controls scheduling;
  // every query, transaction, FK and partial unique index below is real PostgreSQL.
  await db.users.create({ data: { user_id: V, email: 'other-p4@p4.test', name: 'Otro', active: true } });
  await db.club_role_assignments.create({ data: { user_id: V, role_id: assignment.role_id, ecclesiastical_year_id: year, start_date: row.ecclesiastical_year.start_date, status: 'active', active: true, club_section_id: section } });
  const other = await db.enrollments.create({ data: { user_id: V, class_id: cid, ecclesiastical_year_id: year, investiture_status: 'IN_PROGRESS', record_kind: 'OPERATIONAL', active: true } });
  await clear();
  let arrived = 0, release;
  const barrier = new Promise(r => { release = r; });
  const wrapped = new Proxy(db, { get(target, key) {
    if (key === '$transaction') return fn => db.$transaction(tx => fn(new Proxy(tx, { get(t, k) {
      if (k === 'investiture_authorization_people') return new Proxy(t[k], { get(delegate, method) {
        if (method === 'findFirst') return async arg => {
          const result = await delegate.findFirst(arg);
          if (arg.where?.request && arg.where?.status === 'PENDING') {
            assert.equal(result, null); arrived++; if (arrived === 2) release(); await barrier;
          }
          return result;
        };
        const value = delegate[method]; return typeof value === 'function' ? value.bind(delegate) : value;
      } });
      const value = t[k]; return typeof value === 'function' ? value.bind(t) : value;
    } })));
    const value = target[key]; return typeof value === 'function' ? value.bind(target) : value;
  } });
  const racing = new Service(wrapped, eligibility);
  const replies = await Promise.all([eid, other.enrollment_id].map(id => racing.present(auth(section, year), actor, section, year, '2026-11-01', [id], now)));
  const requestCount = await db.investiture_authorization_requests.count();
  const pendingCount = await db.investiture_authorization_people.count({ where: { status: 'PENDING' } });
  const listed = await service.list(auth(section, year), section, year);
  assert.equal(requestCount, 2); assert.equal(pendingCount, 2); assert.equal(listed.people.length, 1);
  assert.notEqual(replies[0].request_id, replies[1].request_id);
  output.push({ case: 'P4-4 distinct users race', requestCount, pendingCount, visibleThroughGet: listed.people.length });
  console.log(JSON.stringify({ reproduced: output, limits: 'Eligibility mocked true and supplied authorization snapshots; no HTTP/auth/UI/production; existing migration NOT applied.' }, null, 2));
})().catch(e => { console.error(String(e).replace(/postgres(?:ql)?:\/\/\S+/gi, '[redacted]')); process.exitCode = 1; }).finally(async () => { await db.$disconnect(); await pool.end(); });
