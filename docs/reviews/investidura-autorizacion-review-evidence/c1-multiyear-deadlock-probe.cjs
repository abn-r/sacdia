// C-1 independent review probe (IA-57/IA-59/IA-60). Exit 0 = observations recorded (not = defects fixed).
// Run ONLY on a throwaway loopback cluster right after
// test/investiture-authorization-requests-postgres.e2e-spec.ts seeded its P4 fixture.
//  A) multi-year class: enrollment started 2025, PENDING in the 2026 request, certificate dated 2026.
//  B) same, certificate dated 2025 (enrollment start year, BEFORE the current/request year).
//  C) control: certificate dated 2019 (before the enrollment start).
//  D) GM multi-year: enrollment 2025, PENDING 2026, GM certificate dated 2026 -> substituteGuideMajor.
//  E) closeYear(2026) vs same-year certificate approval: FOR SHARE(year row) + user advisory cycle.
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
  const pool = new pg.Pool({ connectionString: url.toString(), max: 10 });
  const db = new PrismaClient({ adapter: new PrismaPg(pool) });
  const events = [];
  const service = new Service(db, { calculateForEnrollment: async () => ({ investiture_eligibility: { eligible: true } }) }, { emitEvent: async (dto) => { events.push(dto); return { eventLogId: events.length, queued: false }; } });
  const certs = new CertificateBulkImportApplicationService(db);
  try {
    const y2026 = await db.ecclesiastical_years.findFirstOrThrow({ where: { start_date: D('2026-01-01') } });
    const yearId = y2026.year_id;
    await db.ecclesiastical_years.update({ where: { year_id: yearId }, data: { active: true } });
    const year = async (s, e) => (await db.ecclesiastical_years.findFirst({ where: { start_date: D(s) } })) ?? db.ecclesiastical_years.create({ data: { start_date: D(s), end_date: D(e), active: false } });
    await year('2025-01-01', '2025-12-31');
    await year('2019-01-01', '2019-12-31');
    const a = await db.club_role_assignments.findFirstOrThrow({ where: { user_id: MEMBER, ecclesiastical_year_id: yearId, status: 'active' } });
    const sectionId = a.club_section_id;
    const section = await db.club_sections.findUniqueOrThrow({ where: { club_section_id: sectionId } });
    const field = await db.local_fields.findFirstOrThrow({ where: { abbreviation: 'P4F' } });
    const marker = { grants: { global_roles: [], club_assignments: [{ assignment_id: 'grant-1', role_name: 'director', permissions: [], operational: true, ecclesiastical_year_id: yearId, club: { club_id: 1, club_name: 'P4 Club' }, section: { club_section_id: sectionId, club_type_id: 1 }, scope: {}, status: 'active' }], direct_permissions: [] }, active_assignment: { assignment_id: 'grant-1' }, effective: { permissions: [], scope: { global: {}, club: null } } };
    const fieldAuth = { grants: { global_roles: [{ role_name: 'director-lf', permissions: [], scope: { local_field: { id: field.local_field_id, name: 'Campo' } } }], club_assignments: [], direct_permissions: [] }, active_assignment: { assignment_id: null }, effective: { permissions: [], scope: { global: { local_field: { id: field.local_field_id, name: 'Campo' } }, club: null } } };
    await db.users.update({ where: { user_id: MEMBER }, data: { birthday: D('2000-01-01') } });
    const multi = await db.classes.upsert({ where: { asset_code: 'C1R-MULTI' }, update: { min_duration_years: 1, max_duration_years: 2, active: true }, create: { name: 'Amigo multianual C1R', active: true, club_type_id: section.club_type_id, minimum_age: 10, min_duration_years: 1, max_duration_years: 2, asset_code: 'C1R-MULTI' } });

    async function approve(userId, classId, completedAt) {
      const batch = await db.certificate_bulk_import_batches.create({ data: { user_id: userId, status: 'SUBMITTED', local_field_id: field.local_field_id } });
      const item = await db.certificate_bulk_import_items.create({ data: { batch_id: batch.batch_id, item_type: 'CLASS', class_id: classId, completed_at: completedAt, status: 'SUBMITTED' } });
      return certs.approveItem(MEMBER, batch.batch_id, item.item_id, {});
    }
    async function freshMulti(userId, classId) {
      await db.investiture_authorization_people.deleteMany();
      await db.investiture_authorization_requests.deleteMany();
      await db.local_field_investiture_windows.deleteMany();
      await db.district_investiture_pastors.deleteMany();
      await db.investiture_validation_history.deleteMany({ where: { enrollments: { user_id: userId, class_id: classId } } });
      await db.enrollments.deleteMany({ where: { user_id: userId, class_id: classId } });
      const e = await db.enrollments.create({ data: { user_id: userId, class_id: classId, ecclesiastical_year_id: (await db.ecclesiastical_years.findFirstOrThrow({ where: { start_date: D('2025-01-01') } })).year_id, investiture_status: 'IN_PROGRESS', record_kind: 'OPERATIONAL', active: true } });
      const presented = await service.present(marker, ACTOR, sectionId, yearId, '2026-11-01', [e.enrollment_id], INSIDE);
      return { e, presented };
    }
    async function snapshot(userId, classId, personId) {
      const person = await db.investiture_authorization_people.findUnique({ where: { person_id: personId } });
      const rows = await db.enrollments.findMany({ where: { user_id: userId, class_id: classId }, include: { ecclesiastical_year: { select: { start_date: true } } }, orderBy: { enrollment_id: 'asc' } });
      return { person: person && { status: person.status, resolution_code: person.resolution_code, enrollment_id: person.enrollment_id }, enrollments: rows.map((r) => ({ id: r.enrollment_id, year: r.ecclesiastical_year.start_date.toISOString().slice(0, 4), kind: r.record_kind, status: r.investiture_status })) };
    }
    const settle = async (p) => p.then(() => 'APPROVED', (e) => `REJECTED ${e?.code ?? e?.response?.message ?? e?.message}`);

    // A, B, C
    for (const [label, date] of [['A_cert2026_requestYear', '2026-06-01'], ['B_cert2025_enrollmentStart', '2025-06-01'], ['C_cert2019_control', '2019-06-01']]) {
      const { presented } = await freshMulti(MEMBER, multi.class_id);
      const req = await db.investiture_authorization_requests.findUniqueOrThrow({ where: { request_id: presented.request_id } });
      const result = await settle(approve(MEMBER, multi.class_id, D(date)));
      out[label] = { requestYear: req.ecclesiastical_year_id === yearId ? '2026' : String(req.ecclesiastical_year_id), result, ...(await snapshot(MEMBER, multi.class_id, presented.people[0].person_id)) };
      if (label.startsWith('A')) {
        events.length = 0;
        const resolved = await service.resolve(fieldAuth, ACTOR, presented.request_id, { invest: [{ person_id: presented.people[0].person_id }] }, INSIDE).then((r) => ({ invested: r.invested?.length, retired: (r.retired ?? []).map((p) => p.resolution_code), blocked: (r.blocked ?? []).map((b) => b.code) }), (e) => `ERR ${e?.code ?? e?.message}`);
        out[label].afterPastorResolve = { resolved, classCompleted: events.filter((x) => x.eventType === 'class.completed').length, ...(await snapshot(MEMBER, multi.class_id, presented.people[0].person_id)) };
      }
    }

    // D: GM multi-year
    const gm = await db.classes.upsert({ where: { asset_code: 'GM-01' }, update: { minimum_age: 16, active: true, min_duration_years: 1, max_duration_years: 2 }, create: { name: 'Guia Mayor C1R', active: true, club_type_id: section.club_type_id, minimum_age: 16, min_duration_years: 1, max_duration_years: 2, asset_code: 'GM-01' } });
    await db.users.upsert({ where: { user_id: ANA }, update: { birthday: D('1990-01-01') }, create: { user_id: ANA, email: 'ana-c1r@p4.test', name: 'Ana', active: true, birthday: D('1990-01-01') } });
    await db.club_role_assignments.deleteMany({ where: { user_id: ANA } });
    await db.club_role_assignments.create({ data: { user_id: ANA, role_id: a.role_id, ecclesiastical_year_id: yearId, start_date: D('2026-01-01'), active: true, status: 'active', club_section_id: sectionId } });
    {
      const { presented } = await freshMulti(ANA, gm.class_id);
      const result = await settle(approve(ANA, gm.class_id, D('2026-06-01')));
      out.D_gm_cert2026 = { result, ...(await snapshot(ANA, gm.class_id, presented.people[0].person_id)) };
      const resolved = await service.resolve(fieldAuth, ACTOR, presented.request_id, { invest: [{ person_id: presented.people[0].person_id }] }, INSIDE).then((r) => ({ invested: r.invested?.length, retired: (r.retired ?? []).map((p) => p.resolution_code), blocked: (r.blocked ?? []).map((b) => b.code) }), (e) => `ERR ${e?.code ?? e?.message}`);
      out.D_gm_cert2026.afterPastorResolve = { resolved, ...(await snapshot(ANA, gm.class_id, presented.people[0].person_id)) };
    }

    // E: closeYear vs same-year certificate approval (Amigo P4, 2026 operational enrollment)
    {
      await db.investiture_authorization_people.deleteMany();
      await db.investiture_authorization_requests.deleteMany();
      const amigo = await db.enrollments.findFirstOrThrow({ where: { user_id: MEMBER, ecclesiastical_year_id: yearId, record_kind: 'OPERATIONAL', classes: { asset_code: null } } });
      await db.investiture_validation_history.deleteMany({ where: { enrollments: { user_id: MEMBER, class_id: amigo.class_id, record_kind: 'HISTORICAL_CERTIFICATE' } } });
      await db.enrollments.deleteMany({ where: { user_id: MEMBER, class_id: amigo.class_id, record_kind: 'HISTORICAL_CERTIFICATE' } });
      await db.enrollments.update({ where: { enrollment_id: amigo.enrollment_id }, data: { investiture_status: 'IN_PROGRESS', investiture_date: null, locked_for_validation: false } });
      await service.present(marker, ACTOR, sectionId, yearId, '2026-11-01', [amigo.enrollment_id], INSIDE);
      const holder = new pg.Client({ connectionString: url.toString() });
      await holder.connect();
      await holder.query('BEGIN');
      await holder.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [`${INVESTITURE_REQUEST_USER_LOCK_PREFIX}${MEMBER}`]);
      const holderPid = (await holder.query('SELECT pg_backend_pid() AS pid')).rows[0].pid;
      const observer = new pg.Client({ connectionString: url.toString() });
      await observer.connect();
      const waiters = async (n) => { const end = Date.now() + 10000; while (Date.now() < end) { const r = await observer.query(`SELECT count(*)::int AS c FROM pg_locks WHERE locktype='advisory' AND NOT granted AND pid <> $1`, [holderPid]); if (r.rows[0].c >= n) return; await new Promise((s) => setTimeout(s, 25)); } throw new Error('no advisory waiter'); };
      const yearEnd = new YearEndService(db, { generate: async () => undefined });
      const t0 = Date.now();
      const close = yearEnd.closeYear(yearId).then(() => 'COMMITTED', (e) => `FAILED ${String(e?.code ?? '')} ${String(e?.message ?? e).toLowerCase().includes('deadlock') ? 'DEADLOCK' : String(e?.message ?? e).slice(0, 160)}`);
      await waiters(1);
      const cert = settle(approve(MEMBER, amigo.class_id, D('2026-06-01')));
      await waiters(2);
      const shareHeld = (await observer.query(`SELECT count(*)::int AS c FROM pg_locks l JOIN pg_class c ON c.oid = l.relation WHERE c.relname='ecclesiastical_years' AND l.mode='RowShareLock' AND l.granted`)).rows[0].c;
      await holder.query('COMMIT');
      await holder.end();
      const [closeResult, certResult] = await Promise.all([close, cert]);
      const yr = await db.ecclesiastical_years.findUniqueOrThrow({ where: { year_id: yearId } });
      const pending = await db.investiture_authorization_people.count({ where: { user_id: MEMBER, status: 'PENDING' } });
      await observer.end();
      out.E_closeYear_vs_sameYearCert = { closeYear: closeResult, certificate: certResult, rowShareOnYearsWhileWaiting: shareHeld, yearActiveAfter: yr.active, pendingAfter: pending, ms: Date.now() - t0 };
    }
    console.log(JSON.stringify(out, null, 2));
  } finally {
    await db.$disconnect();
    await pool.end();
  }
})().catch((e) => { console.error('PROBE ERROR', e?.code, e?.message); console.log(JSON.stringify(out, null, 2)); process.exit(1); });
