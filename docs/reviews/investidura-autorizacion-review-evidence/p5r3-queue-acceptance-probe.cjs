// Independent acceptance of P5-2 retained failed job recovery; preserve earlier defect probes.
// Use only after p5r3-postgres-run.sh creates a brand-new isolated cluster and seeds its tests.
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
assert.equal(url.hostname, '127.0.0.1'); assert.equal(url.pathname, '/sacdia_p5r3_review_test'); assert.equal(url.username, 'codex_p5r3_review');
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

  for (const end of ['window','year']) {
    const view=await reset();
    if(end==='year') await db.local_field_investiture_windows.create({data:{local_field_id:field,ecclesiastical_year_id:year,start_date:new Date('2026-10-01'),end_date:new Date('2026-12-31')}});
    let tick=new Date(end==='window'?'2026-12-21T05:59:59Z':'2027-01-01T05:59:59Z');let emissions=0;
    const clockService=new Service(db,eligibility,{emitEvent:async()=>{emissions++;}},{now:()=>tick});
    const holder=await pool.connect();let released=false,job;
    try{
      await holder.query('BEGIN');await holder.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))',[prefix+section+':'+year]);
      job=clockService.resolve(fieldAuth,actor,view.request_id,{invest:[{person_id:view.people[0].person_id}]});job.catch(()=>undefined);
      await waitForWaiter();tick=new Date(tick.getTime()+2000);
      await holder.query('COMMIT');released=true;holder.release();
      const code=end==='window'?'INVESTITURE_REQUEST_WINDOW_CLOSED':'INVESTITURE_REQUEST_YEAR_CLOSED';
      await assert.rejects(job,e=>e.code===code);
      const person=await db.investiture_authorization_people.findUniqueOrThrow({where:{person_id:view.people[0].person_id}});
      assert.equal(person.status,'PENDING');assert.equal(person.achievement_intent_key,null);assert.equal(emissions,0);
      assert.equal((await db.enrollments.findUniqueOrThrow({where:{enrollment_id:e.enrollment_id}})).investiture_status,'IN_PROGRESS');
      observed.push({accepted:'clockCrossesEndOf'+end,code,status:person.status,events:emissions});
    }finally{if(!released){await holder.query('ROLLBACK');holder.release();}if(job)await Promise.allSettled([job]);}
  }
  const {InvestitureAchievementIntentReconciler:Reconciler}=req(root+'/src/investiture-requests/investiture-achievement-intent.reconciler.ts');
  const realCreate=db.achievement_event_log.create.bind(db.achievement_event_log);let failures=1;
  db.achievement_event_log.create=async args=>{if(failures>0){failures--;throw new Error('INJECTED_EVENT_INSERT_FAILURE');}return realCreate(args);};
  const durable=()=>new Service(db,eligibility,new AchievementsService(db,{}, {},undefined));
  const lost=await reset();const lostId=lost.people[0].person_id;const lostKey='investiture-authorization:'+lostId;
  await durable().resolve(fieldAuth,actor,lost.request_id,{invest:[{person_id:lostId}]},now);
  assert.equal(await db.achievement_event_log.count({where:{idempotency_key:lostKey}}),0);
  await db.ecclesiastical_years.update({where:{year_id:year},data:{active:false}});
  await assert.rejects(durable().resolve(fieldAuth,actor,lost.request_id,{invest:[{person_id:lostId}]},now),e=>e.code==='INVESTITURE_REQUEST_YEAR_CLOSED');
  await Promise.all([new Reconciler(durable()).onModuleInit(),new Reconciler(durable()).reconcile()]);
  assert.equal(await db.achievement_event_log.count({where:{idempotency_key:lostKey}}),1);
  observed.push({accepted:'reconcileAfterYearClosedConcurrentStartupAndCron',events:1,postStillRejected:true});
  db.achievement_event_log.create=realCreate;

  // Real isolated Redis, BullMQ Queue + Worker, and real application processor.
  const {Queue,Worker,Job}=req('bullmq');
  const {achievementQueueJobId}=req(root+'/src/achievements/achievements.service.ts');
  const {AchievementsProcessor}=req(root+'/src/achievements/achievements.processor.ts');
  const port=Number(process.env.REVIEW_REDIS_PORT);assert(port>1024&&port<65536);
  const connection={host:'127.0.0.1',port,maxRetriesPerRequest:null};
  const queueName='p5r3-review-'+process.pid;const queue=new Queue(queueName,{connection});let worker;
  let failReads=0,attempts=0;
  const origFind=db.achievement_event_log.findUnique.bind(db.achievement_event_log);
  db.achievement_event_log.findUnique=async args=>{if(failReads>0){failReads--;throw new Error('INJECTED_TRANSIENT_EVENT_READ_FAILURE');}return origFind(args);};
  const processor=new AchievementsProcessor(db,{}, {notifySafe:async()=>undefined});
  const queuedService=new Service(db,eligibility,new AchievementsService(db,{}, {},queue));
  const waitState=async(id,expected)=>{const until=Date.now()+18000;while(Date.now()<until){const j=await queue.getJob(id);if(j&&await j.getState()===expected)return j;await new Promise(r=>setTimeout(r,50));}throw new Error('No job state '+expected);};
  try {
    await queue.waitUntilReady();
    worker=new Worker(queueName,async job=>{attempts++;return processor.process(job);},{connection,concurrency:1});worker.on('error',e=>console.error('worker error',e.message));await worker.waitUntilReady();
    const good=await reset();const id=good.people[0].person_id;const key='investiture-authorization:'+id;const decision={invest:[{person_id:id}]};
    Job.prototype.validateOptions.call({opts:{jobId:achievementQueueJobId(key)},name:'evaluate'},{data:'{}'});
    assert.throws(()=>Job.prototype.validateOptions.call({opts:{jobId:key},name:'evaluate'},{data:'{}'}),/Custom Id cannot contain/);
    await queuedService.resolve(fieldAuth,actor,good.request_id,decision,now);
    const goodJob=await waitState(achievementQueueJobId(key),'completed');
    const retry=await Promise.allSettled([queuedService.resolve(fieldAuth,actor,good.request_id,decision,now),queuedService.resolve(fieldAuth,actor,good.request_id,decision,now)]);
    assert(retry.every(r=>r.status==='rejected'&&r.reason.code==='INVESTITURE_REQUEST_ALREADY_RESOLVED'));
    assert.equal(attempts,1);assert.equal(await db.achievement_event_log.count({where:{idempotency_key:key}}),1);
    assert.equal((await db.achievement_event_log.findUniqueOrThrow({where:{idempotency_key:key}})).processed,true);
    observed.push({accepted:'realRedisBullMqStableIdAndConcurrentRetry',events:1,evaluations:attempts,jobState:await goodJob.getState()});

    const failed=await reset();const failedId=failed.people[0].person_id;const failedKey='investiture-authorization:'+failedId;
    failReads=3;const beforeAttempts=attempts;
    await queuedService.resolve(fieldAuth,actor,failed.request_id,{invest:[{person_id:failedId}]},now);
    const failedJob=await waitState(achievementQueueJobId(failedKey),'failed');
    assert.equal(failReads,0);assert.equal(attempts-beforeAttempts,3);
    await db.ecclesiastical_years.update({where:{year_id:year},data:{active:false}});
    await worker.pause();
    const deliveries=await Promise.all([queuedService.reconcileConfirmedAchievementIntents(),queuedService.reconcileConfirmedAchievementIntents()]);
    const resumed=await queue.getJob(achievementQueueJobId(failedKey));
    assert.equal(await resumed.getState(),'waiting'); assert.equal(resumed.attemptsMade,0);
    assert.equal(attempts-beforeAttempts,3);
    // Reconciliation while waiting must not create another job or reset an active execution.
    await queuedService.reconcileConfirmedAchievementIntents();
    assert.equal(await resumed.getState(),'waiting');
    assert.equal(await db.achievement_event_log.count({where:{idempotency_key:failedKey}}),1);
    await worker.resume();
    const completed=await waitState(achievementQueueJobId(failedKey),'completed');
    assert.equal(completed.id,failedJob.id);assert.equal(completed.attemptsMade,1);
    assert.equal(attempts-beforeAttempts,4);
    assert.equal((await db.achievement_event_log.findUniqueOrThrow({where:{idempotency_key:failedKey}})).processed,true);
    const again=await Promise.all([queuedService.reconcileConfirmedAchievementIntents(),queuedService.reconcileConfirmedAchievementIntents()]);
    assert.deepEqual(again,[0,0]);assert.equal(attempts-beforeAttempts,4);
    await assert.rejects(queuedService.resolve(fieldAuth,actor,failed.request_id,{invest:[{person_id:failedId}]},now),e=>e.code==='INVESTITURE_REQUEST_YEAR_CLOSED');
    observed.push({accepted:'retainedFailedJobRecoveredAfterYearClose',initialFailedAttempts:3,reconcilerReportedDeliveries:deliveries,waitingAttemptsMade:resumed.attemptsMade,finalAttemptsMade:completed.attemptsMade,sameJobId:true,totalWorkerAttempts:attempts-beforeAttempts,state:await completed.getState(),processed:true,eventRows:await db.achievement_event_log.count({where:{idempotency_key:failedKey}}),reconcileAfterProcessed:again});
  }finally{db.achievement_event_log.findUnique=origFind;if(worker)await worker.close();await queue.close();}
  console.log(JSON.stringify({observed,limits:'Real isolated PostgreSQL and Redis/BullMQ Queue+Worker+application processor. Supplied auth and eligibility; injected clock and DB faults. No matching achievements seeded, so successful evaluation verifies processed=true, not a real award. No HTTP/UI/production/migration deployment.'},null,2));
})().catch(e=>{console.error(String(e).replace(/postgres(?:ql)?:\/\/\S+/gi,'[redacted]'));process.exitCode=1;}).finally(async()=>{await db.$disconnect();await pool.end();});
