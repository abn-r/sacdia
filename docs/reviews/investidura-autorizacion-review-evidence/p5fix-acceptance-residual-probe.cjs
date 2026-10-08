// Independent correction acceptance plus residual defect reproduction. Exit 0 validates the stated observations.
// Use only after p5fix-postgres-run.sh creates a brand-new isolated cluster and seeds its tests.
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
assert.equal(url.hostname, '127.0.0.1'); assert.equal(url.pathname, '/sacdia_p5fix_review_test'); assert.equal(url.username, 'codex_p5fix_review');
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
      const result = await job.then(value => ({value}), error => ({error}));
      const expected = {yearClosed:'INVESTITURE_REQUEST_YEAR_CLOSED',windowClosed:'INVESTITURE_REQUEST_WINDOW_CLOSED',pastorRemoved:'INVESTITURE_REQUEST_FORBIDDEN'}[change];
      assert.equal(result.error?.code, expected);
      const saved = await db.enrollments.findUniqueOrThrow({ where: { enrollment_id: e.enrollment_id } });
      const person = await db.investiture_authorization_people.findUniqueOrThrow({where:{person_id:view.people[0].person_id}});
      assert.equal(saved.investiture_status, 'IN_PROGRESS'); assert.equal(person.status,'PENDING'); assert.equal(person.achievement_intent_key,null);
      observed.push({ accepted: change, realAdvisoryWaiter: true, code: expected, status:saved.investiture_status, person:person.status });
    } finally {
      if (!released) { await holder.query('ROLLBACK'); holder.release(); }
      if (job) await Promise.allSettled([job]);
    }
  }
  // Advance only JS wall clock while a real PG lock is awaited. No explicit now argument to resolve.
  const RealDate = Date; let tick = RealDate.parse('2026-12-21T05:59:59.000Z');
  const viewClock = await reset();
  const holder = await pool.connect(); let released=false, clockJob;
  try {
    await holder.query('BEGIN');
    await holder.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [prefix+section+':'+year]);
    global.Date = class extends RealDate { constructor(...args) { super(...(args.length ? args : [tick])); } static now() { return tick; } };
    clockJob=service.resolve(fieldAuth,actor,viewClock.request_id,{invest:[{person_id:viewClock.people[0].person_id}]}); clockJob.catch(()=>undefined);
    await waitForWaiter();
    tick=RealDate.parse('2026-12-21T06:00:01.000Z');
    await holder.query('COMMIT');released=true;holder.release();
    const result=await clockJob; assert.equal(result.invested.length,1);
    let freshCode; try { await service.resolve(fieldAuth,actor,viewClock.request_id,{invest:[{person_id:viewClock.people[0].person_id}]}); } catch(e) {freshCode=e.code;}
    assert.equal(freshCode,'INVESTITURE_REQUEST_WINDOW_CLOSED');
    observed.push({defect:'clockCrossesLocalMidnightWhileWaiting',arrival:'2026-12-20 23:59:59 America/Mexico_City',resume:'2026-12-21 00:00:01 America/Mexico_City',result:'INVESTIDO',freshCode});
  } finally {global.Date=RealDate;if(!released){await holder.query('ROLLBACK');holder.release();}if(clockJob)await Promise.allSettled([clockJob]);}

  const realCreate=db.achievement_event_log.create.bind(db.achievement_event_log);let failures=0;
  db.achievement_event_log.create=async args=>{if(failures>0){failures--;throw new Error('INJECTED_EVENT_INSERT_FAILURE');}return realCreate(args);};
  const makeEventService=()=>new Service(db,eligibility,new AchievementsService(db,{}, {},undefined));
  let eventService=makeEventService();
  const eventView=await reset(); const personId=eventView.people[0].person_id; const key='investiture-authorization:'+personId;
  const decision={invest:[{person_id:personId}]};
  failures=1;
  assert.equal((await eventService.resolve(fieldAuth,actor,eventView.request_id,decision,now)).invested.length,1);
  assert.equal(await db.achievement_event_log.count({where:{idempotency_key:key}}),0);
  // A new service instance represents retry without any in-memory state from the first attempt.
  eventService=makeEventService();
  const retries=await Promise.allSettled([eventService.resolve(fieldAuth,actor,eventView.request_id,decision,now),eventService.resolve(fieldAuth,actor,eventView.request_id,decision,now)]);
  assert(retries.every(r=>r.status==='rejected'&&r.reason.code==='INVESTITURE_REQUEST_ALREADY_RESOLVED'));
  assert.equal(await db.achievement_event_log.count({where:{idempotency_key:key}}),1);
  observed.push({accepted:'failedInsertConcurrentRetriesNewService',events:1,retries:retries.map(r=>r.reason.code)});

  // A confirmed decision must remain recoverable when calendar eligibility expires.
  const lost=await reset(); const lostId=lost.people[0].person_id; const lostKey='investiture-authorization:'+lostId; const lostDecision={invest:[{person_id:lostId}]};
  failures=1;
  assert.equal((await eventService.resolve(fieldAuth,actor,lost.request_id,lostDecision,now)).invested.length,1);
  await db.ecclesiastical_years.update({where:{year_id:year},data:{active:false}});
  let closedError;try{await makeEventService().resolve(fieldAuth,actor,lost.request_id,lostDecision,now);}catch(e){closedError=e.code;}
  assert.equal(closedError,'INVESTITURE_REQUEST_YEAR_CLOSED');
  assert.equal(await db.achievement_event_log.count({where:{idempotency_key:lostKey}}),0);
  observed.push({defect:'recoveryBlockedByClosedYear',status:(await db.investiture_authorization_people.findUniqueOrThrow({where:{person_id:lostId}})).status,intent:(await db.investiture_authorization_people.findUniqueOrThrow({where:{person_id:lostId}})).achievement_intent_key,retryCode:closedError,events:0});

  // Use the installed BullMQ validator, without any Redis connection. Do not mock its validation result.
  const {Job}=req('bullmq'); let queueCalls=0;
  const validationQueue={add:async(name,data,opts)=>{queueCalls++;Job.prototype.validateOptions.call({opts,name},{data:JSON.stringify(data)});return {};}};
  const withQueue=new Service(db,eligibility,new AchievementsService(db,{}, {},validationQueue));
  const queueView=await reset(); const queueId=queueView.people[0].person_id;const queueKey='investiture-authorization:'+queueId;const queueDecision={invest:[{person_id:queueId}]};
  assert.equal((await withQueue.resolve(fieldAuth,actor,queueView.request_id,queueDecision,now)).invested.length,1);
  await assert.rejects(withQueue.resolve(fieldAuth,actor,queueView.request_id,queueDecision,now),e=>e.message==='Custom Id cannot contain :');
  const ev=await db.achievement_event_log.findUniqueOrThrow({where:{idempotency_key:queueKey}});assert.equal(ev.processed,false);assert.equal(queueCalls,2);
  observed.push({defect:'invalidBullMqJobId',jobId:queueKey,queueCalls,error:'Custom Id cannot contain :',persistedEvents:1,processed:ev.processed});
  db.achievement_event_log.create=realCreate;
  console.log(JSON.stringify({observed,limits:'Real PostgreSQL and services; auth snapshots and eligibility stub. Clock advanced in JS, DB insert fault injected; real installed BullMQ validator with queue seam, no Redis connection. No HTTP/UI/cloud/deployed migration.'},null,2));
})().catch(e=>{console.error(String(e).replace(/postgres(?:ql)?:\/\/\S+/gi,'[redacted]'));process.exitCode=1;}).finally(async()=>{await db.$disconnect();await pool.end();});
