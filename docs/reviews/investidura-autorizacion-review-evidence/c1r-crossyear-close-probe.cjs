// C-1 residual independent review probe (2026-10-07). Exit 0 = observations recorded.
// Run ONLY on a throwaway loopback cluster right after
// test/investiture-authorization-requests-postgres.e2e-spec.ts seeded its P4 fixture:
//   SACDIA_TEST_DATABASE_URL=... node -r ts-node/register/transpile-only <this file>   (cwd: sacdia-backend)
// Questions:
//  X) closeYear(2026) vs approval of a 2025 certificate for a person PENDING in the 2026 request.
//     Which ecclesiastical_years rows does the waiting approval hold FOR SHARE (2025? 2026?),
//     both orders forced with a user-advisory holder, plus unforced races. Deadlocks?
//  M) same with a multi-year class (enrollment started 2025) and a reconciliation token.
//  L) certificate dated in a year LATER than the PENDING request year (request 2025 still pending, cert 2026),
//     plain class and Guía Mayor.
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const root = path.resolve(__dirname, '../../../sacdia-backend');
const req = createRequire(root + '/package.json');
const { PrismaClient } = req('@prisma/client');
const { PrismaPg } = req('@prisma/adapter-pg');
const pg = req('pg');
const { InvestitureAuthorizationRequestService: Service } = req(root + '/src/investiture-requests/investiture-authorization-requests.service.ts');
const { CertificateBulkImportApplicationService } = req(root + '/src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts');
const { YearEndService } = req(root + '/src/year-end/year-end.service.ts');
const { INVESTITURE_REQUEST_USER_LOCK_PREFIX } = req(root + '/src/investiture-requests/investiture-request-lock.ts');
const url = new URL(process.env.SACDIA_TEST_DATABASE_URL || 'invalid:');
assert.equal(url.hostname, '127.0.0.1');
assert.ok(url.pathname.endsWith('_test'));
const MEMBER = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const ANA = 'abababab-abab-4aba-8aba-abababababab';
const ACTOR = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const INSIDE = new Date('2026-10-15T18:00:00.000Z');
const D = (s) => new Date(`${s}T00:00:00.000Z`);
const out = {};

(async () => {
  const pool = new pg.Pool({ connectionString: url.toString(), max: 12 });
  const db = new PrismaClient({ adapter: new PrismaPg(pool) });
  const service = new Service(db, { calculateForEnrollment: async () => ({ investiture_eligibility: { eligible: true } }) }, { emitEvent: async () => ({ eventLogId: 1, queued: false }) });
  const certs = new CertificateBulkImportApplicationService(db);
  const observer = new pg.Client({ connectionString: url.toString() });
  await observer.connect();
  const deadlocks = async () => (await observer.query('SELECT deadlocks::int AS d FROM pg_stat_database WHERE datname = current_database()')).rows[0].d;
  try {
    const y2026 = await db.ecclesiastical_years.findFirstOrThrow({ where: { start_date: D('2026-01-01') } });
    const yearId = y2026.year_id;
    const year = async (s, e) => (await db.ecclesiastical_years.findFirst({ where: { start_date: D(s) } })) ?? db.ecclesiastical_years.create({ data: { start_date: D(s), end_date: D(e), active: false } });
    const y2025 = (await year('2025-01-01', '2025-12-31')).year_id;
    const a = await db.club_role_assignments.findFirstOrThrow({ where: { user_id: MEMBER, ecclesiastical_year_id: yearId, status: 'active' } });
    const sectionId = a.club_section_id;
    const section = await db.club_sections.findUniqueOrThrow({ where: { club_section_id: sectionId } });
    const field = await db.local_fields.findFirstOrThrow({ where: { abbreviation: 'P4F' } });
    const marker = { grants: { global_roles: [], club_assignments: [{ assignment_id: 'grant-1', role_name: 'director', permissions: [], operational: true, ecclesiastical_year_id: yearId, club: { club_id: 1, club_name: 'P4 Club' }, section: { club_section_id: sectionId, club_type_id: 1 }, scope: {}, status: 'active' }], direct_permissions: [] }, active_assignment: { assignment_id: 'grant-1' }, effective: { permissions: [], scope: { global: {}, club: null } } };
    await db.users.update({ where: { user_id: MEMBER }, data: { birthday: D('2000-01-01') } });
    const amigo = await db.enrollments.findFirstOrThrow({ where: { user_id: MEMBER, ecclesiastical_year_id: yearId, record_kind: 'OPERATIONAL', classes: { asset_code: null } } });
    const multi = await db.classes.upsert({ where: { asset_code: 'C1RX-MULTI' }, update: { min_duration_years: 1, max_duration_years: 2, active: true }, create: { name: 'Multi C1RX', active: true, club_type_id: section.club_type_id, minimum_age: 10, min_duration_years: 1, max_duration_years: 2, asset_code: 'C1RX-MULTI' } });

    async function newItem(userId, classId, completedAt) {
      const batch = await db.certificate_bulk_import_batches.create({ data: { user_id: userId, status: 'SUBMITTED', local_field_id: field.local_field_id } });
      const item = await db.certificate_bulk_import_items.create({ data: { batch_id: batch.batch_id, item_type: 'CLASS', class_id: classId, completed_at: completedAt, status: 'SUBMITTED' } });
      return { batch, item };
    }
    async function reset() {
      await db.ecclesiastical_years.update({ where: { year_id: yearId }, data: { active: true } });
      await db.investiture_authorization_people.deleteMany();
      await db.investiture_authorization_requests.deleteMany();
      await db.local_field_investiture_windows.deleteMany();
      await db.district_investiture_pastors.deleteMany();
    }
    async function freshOneYear() {
      await reset();
      await db.investiture_validation_history.deleteMany({ where: { enrollments: { user_id: MEMBER, class_id: amigo.class_id, NOT: { enrollment_id: amigo.enrollment_id } } } });
      await db.enrollments.deleteMany({ where: { user_id: MEMBER, class_id: amigo.class_id, NOT: { enrollment_id: amigo.enrollment_id } } });
      await db.enrollments.update({ where: { enrollment_id: amigo.enrollment_id }, data: { investiture_status: 'IN_PROGRESS', investiture_date: null, locked_for_validation: false, record_kind: 'OPERATIONAL', ecclesiastical_year_id: yearId } });
      const presented = await service.present(marker, ACTOR, sectionId, yearId, '2026-11-01', [amigo.enrollment_id], INSIDE);
      return { classId: amigo.class_id, enrollmentId: amigo.enrollment_id, personId: presented.people[0].person_id, requestId: presented.request_id };
    }
    async function freshMulti(userId, classId) {
      await reset();
      await db.investiture_validation_history.deleteMany({ where: { enrollments: { user_id: userId, class_id: classId } } });
      await db.enrollments.deleteMany({ where: { user_id: userId, class_id: classId } });
      const e = await db.enrollments.create({ data: { user_id: userId, class_id: classId, ecclesiastical_year_id: y2025, investiture_status: 'IN_PROGRESS', record_kind: 'OPERATIONAL', active: true } });
      const presented = await service.present(marker, ACTOR, sectionId, yearId, '2026-11-01', [e.enrollment_id], INSIDE);
      const fresh = await db.enrollments.findUniqueOrThrow({ where: { enrollment_id: e.enrollment_id } });
      return { classId, enrollmentId: e.enrollment_id, modifiedAt: fresh.modified_at, personId: presented.people[0].person_id, requestId: presented.request_id };
    }
    const settle = (p) => p.then(() => 'OK', (e) => `ERR ${e?.code ?? ''} ${String(e?.message ?? e).toLowerCase().includes('deadlock') ? 'DEADLOCK' : String(e?.response?.message ?? e?.message ?? e).slice(0, 120)}`);
    async function holdUser() {
      const holder = new pg.Client({ connectionString: url.toString() });
      await holder.connect();
      await holder.query('BEGIN');
      await holder.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [`${INVESTITURE_REQUEST_USER_LOCK_PREFIX}${MEMBER}`]);
      const pid = (await holder.query('SELECT pg_backend_pid() AS pid')).rows[0].pid;
      return { holder, pid };
    }
    const waiters = async (pid, n) => { const end = Date.now() + 10000; while (Date.now() < end) { const r = await observer.query(`SELECT count(*)::int AS c FROM pg_locks WHERE locktype='advisory' AND NOT granted AND pid <> $1`, [pid]); if (r.rows[0].c >= n) return; await new Promise((s) => setTimeout(s, 25)); } throw new Error('no advisory waiter'); };
    // Which year rows are row-locked by someone else right now? (FOR UPDATE NOWAIT in a throwaway tx)
    async function yearRowLocked(id) {
      const c = new pg.Client({ connectionString: url.toString() });
      await c.connect();
      try {
        await c.query('BEGIN');
        await c.query('SELECT year_id FROM ecclesiastical_years WHERE year_id = $1 FOR UPDATE NOWAIT', [id]);
        return false;
      } catch (e) {
        return e.code === '55P03' ? true : `error ${e.code}`;
      } finally {
        await c.query('ROLLBACK').catch(() => undefined);
        await c.end();
      }
    }
    async function state(personId, classId) {
      const person = await db.investiture_authorization_people.findUnique({ where: { person_id: personId } });
      const yr = await db.ecclesiastical_years.findUniqueOrThrow({ where: { year_id: yearId } });
      const rows = await db.enrollments.findMany({ where: { user_id: MEMBER, class_id: classId }, include: { ecclesiastical_year: { select: { start_date: true } } }, orderBy: { enrollment_id: 'asc' } });
      return { person: person && `${person.status}/${person.resolution_code}`, year2026Active: yr.active, enrollments: rows.map((r) => `${r.enrollment_id}:${r.ecclesiastical_year.start_date.toISOString().slice(0, 4)}:${r.record_kind}:${r.investiture_status}`) };
    }
    const yearEnd = new YearEndService(db, { generate: async () => undefined });

    async function forced(label, fresh, certDate, dtoOf, order) {
      const f = await fresh();
      const { batch, item } = await newItem(MEMBER, f.classId, D(certDate));
      const before = await deadlocks();
      const { holder, pid } = await holdUser();
      const startClose = () => settle(yearEnd.closeYear(yearId));
      const startApprove = () => settle(certs.approveItem(MEMBER, batch.batch_id, item.item_id, dtoOf(f)));
      const first = order === 'close-first' ? startClose() : startApprove();
      await waiters(pid, 1);
      const second = order === 'close-first' ? startApprove() : startClose();
      await waiters(pid, 2);
      const rowLocks = { y2025: await yearRowLocked(y2025), y2026: await yearRowLocked(yearId) };
      await holder.query('COMMIT');
      await holder.end();
      const [r1, r2] = await Promise.all([first, second]);
      const close = order === 'close-first' ? r1 : r2;
      const approve = order === 'close-first' ? r2 : r1;
      out[`${label}_${order}`] = { close, approve, yearRowsLockedWhileBothWait: rowLocks, deadlocksDelta: (await deadlocks()) - before, ...(await state(f.personId, f.classId)) };
    }

    // X: one-year class, enrollment 2026, PENDING 2026, certificate 2025
    for (const order of ['close-first', 'approve-first']) {
      await forced('X_oneYear_cert2025', freshOneYear, '2025-06-01', () => ({}), order);
    }
    // M: multi-year, enrollment started 2025, PENDING 2026, certificate 2025 + reconciliation token
    for (const order of ['close-first', 'approve-first']) {
      await forced('M_multi_cert2025_reconcile', () => freshMulti(MEMBER, multi.class_id), '2025-06-01', (f) => ({ reconcile_enrollment_id: f.enrollmentId, expected_modified_at: f.modifiedAt.toISOString() }), order);
    }
    // R: unforced races, 6 rounds alternating start order
    const races = [];
    for (let i = 0; i < 6; i += 1) {
      const f = await freshOneYear();
      const { batch, item } = await newItem(MEMBER, f.classId, D('2025-06-01'));
      const before = await deadlocks();
      const c = () => settle(yearEnd.closeYear(yearId));
      const p = () => settle(certs.approveItem(MEMBER, batch.batch_id, item.item_id, {}));
      const [r1, r2] = i % 2 === 0 ? await Promise.all([c(), p()]) : await Promise.all([p(), c()]);
      const s = await state(f.personId, f.classId);
      races.push({ round: i, close: i % 2 === 0 ? r1 : r2, approve: i % 2 === 0 ? r2 : r1, deadlocksDelta: (await deadlocks()) - before, person: s.person, year2026Active: s.year2026Active, enrollments: s.enrollments.length });
    }
    out.R_unforced_races = races;

    // L: request year 2025 still PENDING (year not closed), certificate dated 2026 (later than the request year)
    {
      const f = await freshMulti(MEMBER, multi.class_id);
      await db.investiture_authorization_requests.update({ where: { request_id: f.requestId }, data: { ecclesiastical_year_id: y2025 } });
      const { batch, item } = await newItem(MEMBER, f.classId, D('2026-06-01'));
      const r = await settle(certs.approveItem(MEMBER, batch.batch_id, item.item_id, {}));
      out.L_multi_request2025_cert2026 = { approve: r, ...(await state(f.personId, f.classId)) };
    }
    {
      const gm = await db.classes.upsert({ where: { asset_code: 'GM-01' }, update: { minimum_age: 16, active: true, min_duration_years: 1, max_duration_years: 2 }, create: { name: 'Guia Mayor C1RX', active: true, club_type_id: section.club_type_id, minimum_age: 16, min_duration_years: 1, max_duration_years: 2, asset_code: 'GM-01' } });
      await db.users.update({ where: { user_id: MEMBER }, data: { birthday: D('1990-01-01') } });
      const f = await freshMulti(MEMBER, gm.class_id);
      await db.investiture_authorization_requests.update({ where: { request_id: f.requestId }, data: { ecclesiastical_year_id: y2025 } });
      const { batch, item } = await newItem(MEMBER, gm.class_id, D('2026-06-01'));
      const r = await settle(certs.approveItem(MEMBER, batch.batch_id, item.item_id, {}));
      out.L_gm_request2025_cert2026 = { approve: r, ...(await state(f.personId, gm.class_id)) };
      await db.classes.update({ where: { class_id: gm.class_id }, data: { max_duration_years: 1 } });
    }
    console.log(JSON.stringify(out, null, 2));
  } finally {
    await observer.end();
    await db.$disconnect();
    await pool.end();
  }
})().catch((e) => { console.error('PROBE ERROR', e?.code, e?.message); console.log(JSON.stringify(out, null, 2)); process.exit(1); });
