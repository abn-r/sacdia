// Independent X-1(d) review probe (2026-10-07). Throwaway loopback PostgreSQL only,
// schema/fixtures prepared by test/investiture-authorization-requests-postgres.e2e-spec.ts.
// Run from sacdia-backend/.
//
// Exercises the conditional enrollments.updateMany in resolve(): a writer that does NOT take
// the enrollment advisory lock (stand-in for certificate reconciliation) changes the row between
// the in-tx re-read and the write. Two people (two users) are resolved in the SAME POST; only
// person A's enrollment is touched by the unlocked writer.
const path = require('node:path');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const root = process.cwd();
require(path.join(root, 'node_modules/ts-node')).register({
  transpileOnly: true, skipProject: true,
  compilerOptions: { module: 'CommonJS', moduleResolution: 'Node', target: 'ES2022', experimentalDecorators: true,
    emitDecoratorMetadata: true, esModuleInterop: true, ignoreDeprecations: '6.0' },
});
require(path.join(root, 'node_modules/reflect-metadata'));
const { PrismaClient } = require(path.join(root, 'node_modules/@prisma/client'));
const { PrismaPg } = require(path.join(root, 'node_modules/@prisma/adapter-pg'));
const { Client } = require(path.join(root, 'node_modules/pg'));
const { InvestitureAuthorizationRequestService: Requests } = require(path.join(root, 'src/investiture-requests/investiture-authorization-requests.service.ts'));

const url = process.env.SACDIA_TEST_DATABASE_URL;
assert(url && new URL(url).hostname === '127.0.0.1' && new URL(url).pathname.endsWith('_test'));
const ACTOR = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const INSIDE = new Date('2026-10-15T18:00:00.000Z');
const db = new PrismaClient({ adapter: new PrismaPg({ connectionString: url }) });
const marker = (s, y) => ({ grants: { global_roles: [], direct_permissions: [], club_assignments: [{ assignment_id: 'grant-1', role_name: 'director', permissions: [], operational: true, ecclesiastical_year_id: y, club: { club_id: 1, club_name: 'P4 Club' }, section: { club_section_id: s, club_type_id: 1 }, scope: {}, status: 'active' }] }, active_assignment: { assignment_id: 'grant-1' }, effective: { permissions: [], scope: { global: {}, club: null } } });
const fieldAuth = (f) => ({ grants: { global_roles: [{ role_name: 'director-lf', permissions: [], scope: { local_field: { id: f, name: 'Campo' } } }], club_assignments: [], direct_permissions: [] }, active_assignment: { assignment_id: null }, effective: { permissions: [], scope: { global: { local_field: { id: f, name: 'Campo' } }, club: null } } });

(async () => {
  const section = await db.club_sections.findFirst({ where: { club_types: { name: 'Conquistadores' } }, orderBy: { club_section_id: 'asc' } });
  const cls = await db.classes.findFirst({ where: { name: 'Amigo P4' } });
  const year = await db.ecclesiastical_years.findFirst({ where: { start_date: new Date('2026-01-01') }, orderBy: { year_id: 'asc' } });
  const field = await db.local_fields.findFirst({ where: { abbreviation: 'P4F' } });
  const role = await db.roles.findFirst({ where: { role_name: 'member', role_category: 'CLUB' } });
  assert(section && cls && year && field && role);
  await db.ecclesiastical_years.update({ where: { year_id: year.year_id }, data: { active: true } });
  const enrollments = [];
  for (const tag of ['A', 'B']) {
    const user = randomUUID();
    await db.users.create({ data: { user_id: user, email: `x1x4-guard-${tag}-${user}@example.test`, name: `Guard ${tag}`, active: true, local_field_id: field.local_field_id } });
    await db.club_role_assignments.create({ data: { user_id: user, role_id: role.role_id, ecclesiastical_year_id: year.year_id, start_date: new Date('2026-01-01'), active: true, status: 'active', club_section_id: section.club_section_id } });
    enrollments.push(await db.enrollments.create({ data: { user_id: user, class_id: cls.class_id, ecclesiastical_year_id: year.year_id, investiture_status: 'IN_PROGRESS', record_kind: 'OPERATIONAL', active: true } }));
  }
  const events = [];
  const requests = new Requests(db, { calculateForEnrollment: async () => ({ investiture_eligibility: { eligible: true } }) },
    { emitEvent: async (dto) => { events.push(dto); return { eventLogId: events.length, queued: false }; } });
  const presented = await requests.present(marker(section.club_section_id, year.year_id), ACTOR, section.club_section_id, year.year_id, '2026-11-01', enrollments.map((e) => e.enrollment_id), INSIDE);
  const people = presented.people;
  assert.equal(people.length, 2);
  const target = enrollments[0];

  const writer = new Client({ connectionString: url });
  const observer = new Client({ connectionString: url });
  await writer.connect(); await observer.connect();
  let outcome;
  try {
    // Unlocked writer (no advisory lock): row lock + uncommitted INVESTIDO on person A's enrollment.
    await writer.query('BEGIN');
    await writer.query("UPDATE enrollments SET investiture_status = 'INVESTIDO' WHERE enrollment_id = $1", [target.enrollment_id]);
    const writerPid = (await writer.query('SELECT pg_backend_pid() AS pid')).rows[0].pid;
    const resolving = requests.resolve(fieldAuth(field.local_field_id), ACTOR, presented.request_id,
      { invest: people.map((p) => ({ person_id: p.person_id })) }, INSIDE)
      .then((v) => ({ ok: true, invested: v.invested.length, retired: v.retired.length }), (e) => ({ ok: false, code: e?.response?.code ?? e?.message }));
    // wait until resolve blocks on the row lock held by the writer
    const deadline = Date.now() + 10000;
    for (;;) {
      const r = await observer.query("SELECT count(*)::int AS n FROM pg_locks WHERE locktype = 'transactionid' AND NOT granted AND pid <> $1", [writerPid]);
      if (r.rows[0].n > 0) break;
      if (Date.now() > deadline) throw new Error('resolve never blocked on the row lock');
      await new Promise((res) => setTimeout(res, 20));
    }
    await writer.query('COMMIT');
    outcome = await resolving;
  } finally {
    try { await writer.query('ROLLBACK'); } catch { /* ended */ }
    await writer.end(); await observer.end();
  }
  const rows = await db.investiture_authorization_people.findMany({ where: { request_id: presented.request_id }, orderBy: { enrollment_id: 'asc' } });
  const enr = await db.enrollments.findMany({ where: { enrollment_id: { in: enrollments.map((e) => e.enrollment_id) } }, orderBy: { enrollment_id: 'asc' } });
  const result = {
    resolve: outcome,
    people: rows.map((r) => ({ enrollment_id: r.enrollment_id, status: r.status, resolution_code: r.resolution_code })),
    enrollments: enr.map((e) => ({ enrollment_id: e.enrollment_id, investiture_status: e.investiture_status })),
    class_completed_events: events.filter((e) => e.eventType === 'class.completed').length,
  };
  console.log(JSON.stringify(result, null, 2));
  await db.investiture_authorization_people.deleteMany({ where: { request_id: presented.request_id } });
  await db.investiture_authorization_requests.deleteMany({ where: { request_id: presented.request_id } });
  await db.$disconnect();
})().catch(async (e) => { console.error('PROBE ERROR', e); await db.$disconnect(); process.exit(1); });
