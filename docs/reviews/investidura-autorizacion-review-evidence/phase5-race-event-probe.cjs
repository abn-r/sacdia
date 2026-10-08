// Independent defect reproduction, NOT acceptance: exit 0 means the defects were observed.
// Use only after phase5-postgres-run.sh creates a brand-new isolated cluster and seeds its tests.
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const root = path.resolve(__dirname, '../../../sacdia-backend');
const req = createRequire(root + '/package.json');
const { PrismaClient } = req('@prisma/client');
const { PrismaPg } = req('@prisma/adapter-pg');
const { Pool } = req('pg');
const { InvestitureAuthorizationRequestService: Service } = req(root + '/src/investiture-requests/investiture-authorization-requests.service.ts');
const { AchievementsService } = req(root + '/src/achievements/achievements.service.ts');
const { INVESTITURE_REQUEST_SECTION_LOCK_PREFIX: prefix } = req(root + '/src/investiture-requests/investiture-request-lock.ts');
const url = new URL(process.env.SACDIA_TEST_DATABASE_URL || 'invalid:');
assert.equal(url.hostname, '127.0.0.1'); assert.equal(url.pathname, '/sacdia_phase5_review_test'); assert.equal(url.username, 'codex_phase5_review');
const pool = new Pool({ connectionString: url.toString(), max: 8 });
const db = new PrismaClient({ adapter: new PrismaPg(pool) });
const U = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', actor = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const now = new Date('2026-10-15T18:00:00Z');
const eligibility = { calculateForEnrollment: async () => ({ investiture_eligibility: { eligible: true } }) };
const service = new Service(db, eligibility, { emitEvent: async () => ({ queued: false }) });
(async () => {
  const e = await db.enrollments.findFirstOrThrow({ where: { user_id: U } });
  const a = await db.club_role_assignments.findFirstOrThrow({ where: { user_id: U, status: 'active' } });
  const section = a.club_section_id, year = a.ecclesiastical_year_id;
  const s = await db.club_sections.findUniqueOrThrow({ where: { club_section_id: section }, include: { clubs: { include: { churches: true } } } });
  const field = s.clubs.local_field_id, district = s.clubs.churches.districlub_type_id;
  const marker = { grants: { global_roles: [], club_assignments: [{ role_name: 'director', operational: true, status: 'active', ecclesiastical_year_id: year, section: { club_section_id: section } }] } };
  const fieldAuth = { grants: { global_roles: [{ role_name: 'director-lf' }] }, effective: { scope: { global: { local_field: { id: field } } } } };
  const pastorAuth = { grants: { global_roles: [{ role_name: 'pastor' }] } };
  async function reset() {
    await db.investiture_authorization_people.deleteMany();
    await db.investiture_authorization_requests.deleteMany();
    await db.local_field_investiture_windows.deleteMany();
    await db.district_investiture_pastors.deleteMany();
    await db.ecclesiastical_years.update({ where: { year_id: year }, data: { active: true } });
    await db.enrollments.update({ where: { enrollment_id: e.enrollment_id }, data: { investiture_status: 'IN_PROGRESS', investiture_date: null } });
    return service.present(marker, actor, section, year, '2026-11-01', [e.enrollment_id], now);
  }
  async function waitForWaiter() {
    const end = Date.now() + 3000;
    while (Date.now() < end) {
      const r = await pool.query("SELECT count(*)::int AS n FROM pg_locks WHERE locktype='advisory' AND NOT granted");
      if (r.rows[0].n > 0) return;
      await new Promise(r => setTimeout(r, 10));
    }
    throw new Error('No real PostgreSQL advisory waiter');
  }
  const observed = [];
  for (const change of ['yearClosed', 'windowClosed', 'pastorRemoved']) {
    const view = await reset();
    if (change === 'pastorRemoved') await db.district_investiture_pastors.create({ data: { districlub_type_id: district, user_id: actor, active: true } });
    const auth = change === 'pastorRemoved' ? pastorAuth : fieldAuth;
    const holder = await pool.connect(); let released = false, job;
    try {
      await holder.query('BEGIN');
      await holder.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [prefix + section + ':' + year]);
      job = service.resolve(auth, actor, view.request_id, { invest: [{ person_id: view.people[0].person_id }] }, now); job.catch(() => undefined);
      await waitForWaiter();
      if (change === 'yearClosed') await db.ecclesiastical_years.update({ where: { year_id: year }, data: { active: false } });
      if (change === 'windowClosed') await db.local_field_investiture_windows.create({ data: { local_field_id: field, ecclesiastical_year_id: year, start_date: new Date('2026-10-01'), end_date: new Date('2026-10-14') } });
      if (change === 'pastorRemoved') await db.district_investiture_pastors.updateMany({ where: { user_id: actor }, data: { active: false } });
      // The concurrent configuration change is already committed before resolving resumes.
      await holder.query('COMMIT'); released = true; holder.release();
      const result = await job;
      assert.equal(result.invested.length, 1);
      const saved = await db.enrollments.findUniqueOrThrow({ where: { enrollment_id: e.enrollment_id } });
      assert.equal(saved.investiture_status, 'INVESTIDO');
      // A fresh resolution attempt sees and rejects the changed context.
      let freshCode;
      try { await service.resolve(auth, actor, view.request_id, { invest: [{ person_id: view.people[0].person_id }] }, now); }
      catch (err) { freshCode = err.code; }
      assert(freshCode && freshCode !== 'INVESTITURE_REQUEST_ALREADY_RESOLVED');
      observed.push({ scenario: change, realAdvisoryWaiter: true, configurationCommittedBeforeResolution: true, result: saved.investiture_status, freshAttemptCode: freshCode });
    } finally {
      if (!released) { await holder.query('ROLLBACK'); holder.release(); }
      if (job) await Promise.allSettled([job]);
    }
  }
  // Exercise the real AchievementsService with only its DB event insert fault-injected.
  const view = await reset(); let insertAttempts = 0;
  const achievementDb = { achievement_event_log: { create: async args => { insertAttempts++; if (insertAttempts === 1) throw new Error('INJECTED_EVENT_INSERT_FAILURE'); return db.achievement_event_log.create(args); } } };
  const achievements = new AchievementsService(achievementDb, {}, {}, undefined);
  const eventService = new Service(db, eligibility, achievements);
  const before = await db.achievement_event_log.count({ where: { user_id: U, event_type: 'class.completed' } });
  const decision = { invest: [{ person_id: view.people[0].person_id }] };
  const result = await eventService.resolve(fieldAuth, actor, view.request_id, decision, now);
  assert.equal(result.invested.length, 1);
  await assert.rejects(eventService.resolve(fieldAuth, actor, view.request_id, decision, now), err => err.code === 'INVESTITURE_REQUEST_ALREADY_RESOLVED');
  assert.equal(insertAttempts, 1);
  const after = await db.achievement_event_log.count({ where: { user_id: U, event_type: 'class.completed' } });
  assert.equal(after, before);
  observed.push({ scenario: 'eventInsertFailsOnce', resolveSucceeded: true, status: (await db.enrollments.findUniqueOrThrow({ where: { enrollment_id: e.enrollment_id } })).investiture_status, eventInsertAttemptsAfterRetry: insertAttempts, persistedEventsAdded: after - before, retry: 'INVESTITURE_REQUEST_ALREADY_RESOLVED' });
  console.log(JSON.stringify({ defectsReproduced: observed, limits: 'Real service and PostgreSQL; supplied auth snapshots and eligibility stub. Event test uses real AchievementsService with transient DB insert fault injection. No HTTP, cloud, existing DB, migration deployment or UI.' }, null, 2));
})().catch(e => { console.error(String(e).replace(/postgres(?:ql)?:\/\/\S+/gi, '[redacted]')); process.exitCode = 1; }).finally(async () => { await db.$disconnect(); await pool.end(); });
