// Independent X-1 review probe (2026-10-07). Runs ONLY against a throwaway loopback
// PostgreSQL whose schema was already prepared by
// test/investiture-authorization-requests-postgres.e2e-spec.ts (P4 fixtures).
// Run from sacdia-backend/:  SACDIA_TEST_DATABASE_URL=... node ../docs/reviews/investidura-autorizacion-review-evidence/x1x4-legacy-submit-race-probe.cjs
//
// Question: a legacy write path that reads investiture_status OUTSIDE its transaction and
// then writes with an UNCONDITIONAL update (submitForValidation, ValidationService.submitClassForReview)
// can wait on the enrollment advisory lock while the new-flow resolution holds it. When the
// resolution commits INVESTIDO the PENDING row is gone, so the legacy path passes the
// PENDING check and overwrites INVESTIDO.
const path = require('node:path');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const root = process.cwd();
require(path.join(root, 'node_modules/ts-node')).register({
  transpileOnly: true,
  skipProject: true,
  compilerOptions: {
    module: 'CommonJS', moduleResolution: 'Node', target: 'ES2022',
    experimentalDecorators: true, emitDecoratorMetadata: true, esModuleInterop: true,
    ignoreDeprecations: '6.0',
  },
});
require(path.join(root, 'node_modules/reflect-metadata'));
const { PrismaClient } = require(path.join(root, 'node_modules/@prisma/client'));
const { PrismaPg } = require(path.join(root, 'node_modules/@prisma/adapter-pg'));
const { Client } = require(path.join(root, 'node_modules/pg'));
const { InvestitureAuthorizationRequestService: Requests } = require(path.join(root, 'src/investiture-requests/investiture-authorization-requests.service.ts'));
const { INVESTITURE_REQUEST_ENROLLMENT_LOCK_PREFIX } = require(path.join(root, 'src/investiture-requests/investiture-request-lock.ts'));
const { InvestitureService } = require(path.join(root, 'src/investiture/investiture.service.ts'));
const { ValidationService } = require(path.join(root, 'src/validation/validation.service.ts'));

const url = process.env.SACDIA_TEST_DATABASE_URL;
assert(url && new URL(url).hostname === '127.0.0.1' && new URL(url).pathname.endsWith('_test'));
const ACTOR = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const INSIDE = new Date('2026-10-15T18:00:00.000Z');
const db = new PrismaClient({ adapter: new PrismaPg({ connectionString: url }) });

function marker(sectionId, yearId) {
  return {
    grants: {
      global_roles: [], direct_permissions: [],
      club_assignments: [{ assignment_id: 'grant-1', role_name: 'director', permissions: [], operational: true,
        ecclesiastical_year_id: yearId, club: { club_id: 1, club_name: 'P4 Club' },
        section: { club_section_id: sectionId, club_type_id: 1 }, scope: {}, status: 'active' }],
    },
    active_assignment: { assignment_id: 'grant-1' },
    effective: { permissions: [], scope: { global: {}, club: null } },
  };
}
function fieldAuth(fieldId) {
  return {
    grants: { global_roles: [{ role_name: 'director-lf', permissions: [], scope: { local_field: { id: fieldId, name: 'Campo' } } }],
      club_assignments: [], direct_permissions: [] },
    active_assignment: { assignment_id: null },
    effective: { permissions: [], scope: { global: { local_field: { id: fieldId, name: 'Campo' } }, club: null } },
  };
}
async function waiters(observer, holderPid, count) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    const r = await observer.query(
      "SELECT count(*)::int AS n FROM pg_locks WHERE locktype='advisory' AND NOT granted AND pid <> $1", [holderPid]);
    if (r.rows[0].n >= count) return;
    await new Promise((res) => setTimeout(res, 20));
  }
  throw new Error(`expected ${count} advisory waiters`);
}

async function scenario(label, startLegacy) {
  const section = await db.club_sections.findFirst({ where: { club_types: { name: 'Conquistadores' } }, orderBy: { club_section_id: 'asc' } });
  const cls = await db.classes.findFirst({ where: { name: 'Amigo P4' } });
  const year = await db.ecclesiastical_years.findFirst({ where: { start_date: new Date('2026-01-01') }, orderBy: { year_id: 'asc' } });
  const field = await db.local_fields.findFirst({ where: { abbreviation: 'P4F' } });
  const role = await db.roles.findFirst({ where: { role_name: 'member', role_category: 'CLUB' } });
  assert(section && cls && year && field && role, 'P4 fixtures missing: run the e2e first');
  await db.ecclesiastical_years.update({ where: { year_id: year.year_id }, data: { active: true } });
  const user = randomUUID();
  await db.users.create({ data: { user_id: user, email: `x1x4-${user}@example.test`, name: 'X1X4', active: true, local_field_id: field.local_field_id } });
  await db.club_role_assignments.create({ data: { user_id: user, role_id: role.role_id, ecclesiastical_year_id: year.year_id,
    start_date: new Date('2026-01-01'), active: true, status: 'active', club_section_id: section.club_section_id } });
  const enr = await db.enrollments.create({ data: { user_id: user, class_id: cls.class_id, ecclesiastical_year_id: year.year_id,
    investiture_status: 'IN_PROGRESS', record_kind: 'OPERATIONAL', active: true } });
  await db.investiture_config.deleteMany({ where: { local_field_id: field.local_field_id, ecclesiastical_year_id: year.year_id } });
  await db.investiture_config.create({ data: { local_field_id: field.local_field_id, ecclesiastical_year_id: year.year_id,
    submission_deadline: new Date('2026-12-01T00:00:00Z'), investiture_date: new Date('2026-11-01T00:00:00Z'), active: true } });

  const events = [];
  const achievements = { emitEvent: async (dto) => { events.push(dto); return { eventLogId: events.length, queued: false }; } };
  const requests = new Requests(db, { calculateForEnrollment: async () => ({ investiture_eligibility: { eligible: true } }) }, achievements);
  const notifications = { notifySafe: async () => undefined, sendToSectionRole: async () => undefined, sendToGlobalRole: async () => undefined };
  const eligibility = { calculateForEnrollment: async () => ({ investiture_eligibility: { eligible: true, total: 1, completed: 1 } }) };
  const legacy = new InvestitureService(db, {}, notifications, achievements, {}, eligibility);
  const validation = new ValidationService(db, notifications, {});

  const presented = await requests.present(marker(section.club_section_id, year.year_id), ACTOR, section.club_section_id, year.year_id,
    '2026-11-01', [enr.enrollment_id], INSIDE);
  const personId = presented.people[0].person_id;

  const holder = new Client({ connectionString: url });
  const observer = new Client({ connectionString: url });
  await holder.connect(); await observer.connect();
  let resolveOutcome, legacyOutcome;
  try {
    await holder.query('BEGIN');
    await holder.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [`${INVESTITURE_REQUEST_ENROLLMENT_LOCK_PREFIX}${enr.enrollment_id}`]);
    const pid = (await holder.query('SELECT pg_backend_pid() AS pid')).rows[0].pid;
    const resolving = requests.resolve(fieldAuth(field.local_field_id), ACTOR, presented.request_id, { invest: [{ person_id: personId }] }, INSIDE)
      .then((v) => ({ ok: true, invested: v.invested.length }), (e) => ({ ok: false, code: e?.response?.code ?? e?.message }));
    await waiters(observer, pid, 1);
    const legacyRun = startLegacy({ legacy, validation, enr, user })
      .then((v) => ({ ok: true, status: v?.investiture_status }), (e) => ({ ok: false, code: e?.response?.code ?? e?.response?.message ?? e?.message }));
    await waiters(observer, pid, 2);
    await holder.query('COMMIT');
    [resolveOutcome, legacyOutcome] = await Promise.all([resolving, legacyRun]);
  } finally {
    try { await holder.query('ROLLBACK'); } catch { /* already ended */ }
    await holder.end(); await observer.end();
  }
  const after = await db.enrollments.findUnique({ where: { enrollment_id: enr.enrollment_id } });
  const person = await db.investiture_authorization_people.findUnique({ where: { person_id: personId } });
  const result = {
    scenario: label,
    resolve: resolveOutcome,
    legacy: legacyOutcome,
    person_status: person.status,
    enrollment_status: after.investiture_status,
    locked_for_validation: after.locked_for_validation,
    class_completed_events: events.filter((e) => e.eventType === 'class.completed').length,
  };
  // cleanup of probe-owned rows
  await db.investiture_validation_history.deleteMany({ where: { enrollment_id: enr.enrollment_id } });
  await db.validation_logs.deleteMany({ where: { entity_id: String(enr.enrollment_id), entity_type: 'class' } });
  await db.investiture_message_dispatches.deleteMany({}).catch(() => undefined);
  await db.investiture_authorization_people.deleteMany({ where: { user_id: user } });
  await db.investiture_authorization_requests.deleteMany({ where: { request_id: presented.request_id } });
  await db.investiture_config.deleteMany({ where: { local_field_id: field.local_field_id, ecclesiastical_year_id: year.year_id } });
  return result;
}

(async () => {
  const out = [];
  out.push(await scenario('resolve holds lock, then InvestitureService.submitForValidation',
    ({ legacy, enr, user }) => legacy.submitForValidation(enr.enrollment_id, user, {})));
  out.push(await scenario('resolve holds lock, then ValidationService.submitForReview(class)',
    ({ validation, enr, user }) => validation.submitForReview('class', enr.enrollment_id, user)));
  console.log(JSON.stringify(out, null, 2));
  const overwritten = out.filter((r) => r.person_status === 'INVESTED' && r.enrollment_status !== 'INVESTIDO');
  console.log(overwritten.length
    ? `RESULT: ${overwritten.length}/${out.length} scenarios end with person INVESTED but enrollment overwritten (X-1 race open)`
    : 'RESULT: no overwrite observed');
  await db.$disconnect();
})().catch(async (e) => { console.error('PROBE ERROR', e); await db.$disconnect(); process.exit(1); });
