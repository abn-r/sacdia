// Independent phase-6 probes. Real methods, synthetic Prisma/queue/provider only.
// Run from sacdia-backend; no network, database, Redis or real email.
const path = require('node:path');
const assert = require('node:assert/strict');
const root = process.cwd();
require(path.join(root, 'node_modules/ts-node')).register({
  transpileOnly: true, skipProject: true,
  compilerOptions: { module: 'CommonJS', moduleResolution: 'Node', target: 'ES2022', experimentalDecorators: true, emitDecoratorMetadata: true, esModuleInterop: true, jsx: 'react', ignoreDeprecations: '6.0' },
});
require(path.join(root, 'node_modules/reflect-metadata'));
const { InvestitureCommunicationsService: Communications } = require(path.join(root, 'src/investiture-requests/investiture-communications.service.ts'));
const { EmailService } = require(path.join(root, 'src/common/email/email.service.ts'));
const { EmailQueueProducer } = require(path.join(root, 'src/common/email/email.queue.ts'));
const { EmailProcessor } = require(path.join(root, 'src/common/email/email.processor.ts'));
const { NotificationsService } = require(path.join(root, 'src/notifications/notifications.service.ts'));
const { deliverOnce } = require(path.join(root, 'src/investiture-requests/investiture-dispatch.ts'));
const config = { get: (key) => key === 'ADMIN_PANEL_URL' ? 'https://admin.example.test' : undefined };
const REQUEST = '99999999-9999-4999-8999-999999999999';
const PERSON = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const PASTOR = '11111111-1111-4111-8111-111111111111';
const instant = new Date('2026-10-05T16:00:00Z');
const RealDate = Date;
global.Date = class extends RealDate { constructor(...args) { super(...(args.length ? args : [instant.getTime()])); } static now() { return instant.getTime(); } };
function db() {
  const rows = [];
  const state = { roleActive: true, yearActive: true, pending: true, failSent: false, rows };
  const matches = (row, where) => Object.entries(where).every(([k,v]) => k === 'status' ? v.in.includes(row.status) : row[k] === v);
  const person = { person_id: PERSON, request_id: REQUEST, enrollment_id: 1, user_id: PERSON, class_id: 1, status: 'PENDING', investiture_date: new Date('2026-11-01') };
  const req = { request_id: REQUEST, club_section_id: 1, ecclesiastical_year_id: 1, created_at: new Date('2026-09-21') };
  const section = { club_section_id: 1, club_types: { name: 'Conquistadores' }, clubs: { local_field_id: 10, local_fields: { timezone: 'America/Mexico_City' }, churches: { districlub_type_id: 4 } } };
  const prisma = {
    investiture_message_dispatches: {
      findUnique: async ({where}) => rows.find(r => matches(r, where.uq_investiture_message_dispatch)) ?? null,
      findMany: async ({where}) => rows.filter(r => matches(r, where)),
      create: async ({data}) => { rows.push({...data}); return data; },
      updateMany: async ({where,data}) => {
        if (state.failSent && data.status === 'sent') { state.failSent = false; throw Error('ack write failed'); }
        const found = rows.filter(r => matches(r,where));
        for (const row of found) Object.assign(row, Object.fromEntries(Object.entries(data).filter(([,v])=>v!==undefined)));
        return {count:found.length};
      },
    },
    investiture_authorization_requests: { findUnique: async()=>req, findMany: async()=>[req] },
    investiture_authorization_people: { findMany: async()=>state.pending?[person]:[] },
    club_sections: { findUnique: async()=>section, findMany: async()=>[section] },
    ecclesiastical_years: { findMany: async()=>[{year_id:1,active:state.yearActive,start_date:new Date('2026-01-01'),end_date:new Date('2026-12-31')}] },
    local_field_investiture_windows: {findMany:async()=>[]},
    district_investiture_pastors: {findMany:async()=>state.roleActive?[{user_id:PASTOR,districlub_type_id:4,active:true}]:[]},
    users_roles: {findMany:async()=>[]},
    club_role_assignments: {findMany:async()=>[]},
    users: {findMany:async({where})=>where.user_id.in.map(id=>({user_id:id,name:id===PERSON?'Ana':'Pastor',email:'synthetic@example.test',active:true}))},
    classes: {findMany:async()=>[{class_id:1,name:'Amigo'}]},
  };
  return {prisma,state};
}
const presentation = { kind:'PRESENTATION',executionKey:'batch-1',recipientUserId:PASTOR,email:'synthetic@example.test',role:'pastor',scopeKey:'district:4',subject:'Test',paragraphs:['Ana'],link:'https://admin.example.test/request'};
const result = {kind:'RESULT',executionKey:'person-invested:'+PERSON,recipientUserId:PERSON,role:'person',scopeKey:'user:'+PERSON,title:'Investidura',body:'Confirmada',source:'investiture:invested',requestId:REQUEST};
const passed=[];
function pass(id,detail){passed.push(id); console.log(JSON.stringify({id,...detail}));}
(async()=>{
  // P6-1: a transient read failure after the decision leaves no durable intent.
  {
    const {prisma,state}=db(); let attempts=0;
    prisma.investiture_authorization_requests.findUnique=async()=>{throw Error('transient post-commit read failure');};
    const service=new Communications(prisma,{sendInvestitureNotice:async()=>{attempts++;}},{sendToUser:async()=>{attempts++;}},config);
    await service.recordPresentation({requestId:REQUEST,enrollmentIds:[1]});
    await service.recordResults({requestId:REQUEST,actorId:PASTOR,investedIds:[PERSON],rejectedPersonIds:[],rejectedSystemIds:[]});
    assert.equal(await service.deliverPending(),0); assert.equal(state.rows.length,0); assert.equal(attempts,0);
    pass('P6-1-postcommit-loss',{rows:0,reconciled:0});
  }
  // P6-2: queue acceptance is marked sent; actual provider failures never update it.
  {
    const {prisma,state}=db(); const jobs=[];
    const producer=new EmailQueueProducer({add:async(name,data,opts)=>{jobs.push({name,data,opts,id:opts.jobId,attemptsMade:0});}});
    const service=new Communications(prisma,new EmailService(producer),{},config);
    assert.equal(await service.sendMail(presentation),'sent');
    let failures=0; process.env.EMAIL_ENABLED='true';
    const worker=new EmailProcessor({send:async()=>{failures++;throw Error('provider unavailable');}},config,{});
    worker.renderTemplate=async()=>({subject:'Probe',html:'<p>Probe</p>',text:'Probe'}); // Isolate pre-existing local React version mismatch; not template acceptance.
    for(let i=0;i<5;i++){jobs[0].attemptsMade=i;await assert.rejects(worker.process(jobs[0]),/provider unavailable/);}
    assert.equal(await service.deliverPending(),0); assert.equal(state.rows[0].status,'sent'); assert.equal(jobs.length,1); assert.equal(failures,5);
    pass('P6-2-queue-ack-not-delivery',{dispatch:state.rows[0].status,providerFailures:failures,reconciled:0});
  }
  // P6-2: a process crash after claim is represented by durable sending state.
  {
    const key={kind:'REMINDER',executionKey:'2026-10-05',recipientUserId:PASTOR,role:'pastor',scopeKey:'field:10',payload:{}};
    let sends=0;
    const store={find:async()=>({...key,dispatchId:'existing',status:'sending',attempts:1}),create:async()=>{throw Error('unexpected');},updateWhere:async()=>{throw Error('unexpected');}};
    assert.equal(await deliverOnce(store,key,'new',async()=>{sends++;}),'duplicate'); assert.equal(sends,0);
    pass('P6-2-stranded-sending',{outcome:'duplicate',sends});
  }
  // P6-3: failed reminder is retried after losing district assignment.
  {
    const {prisma,state}=db(); let fail=true; const sent=[]; const attempts=[];
    const service=new Communications(prisma,{sendInvestitureNotice:async(mail)=>{attempts.push(mail);if(fail)throw Error('queue down');sent.push(mail);}}, {}, config);
    assert.equal(await service.dispatchReminders(instant),0);
    assert.equal(state.rows[0].status,'failed');
    assert(!attempts[0].paragraphs.some(p=>p.includes('ventana de autorización está cerrada')));
    state.roleActive=false; fail=false;
    assert.equal(await service.deliverPending(),1); assert.equal(sent.length,1);
    assert.equal(sent[0].to,'synthetic@example.test'); assert(sent[0].paragraphs.some(p=>p.includes('Ana')));
    // No explicit window: default October-December is open, but retry claims closed.
    assert(sent[0].paragraphs.some(p=>p.includes('ventana de autorización está cerrada')));
    pass('P6-3-revoked-pastor-and-window-drift',{roleActive:false,sent:1,closedWarning:true});
  }
  // P6-3: queued worker sends a reminder even after year closure and no pending.
  {
    const {prisma,state}=db(); const jobs=[]; const messages=[];
    const producer=new EmailQueueProducer({add:async(name,data,opts)=>jobs.push({name,data,opts,id:opts.jobId,attemptsMade:0})});
    const service=new Communications(prisma,new EmailService(producer),{},config);
    assert.equal(await service.dispatchReminders(instant),1);
    state.yearActive=false;state.pending=false;state.roleActive=false;
    const worker=new EmailProcessor({send:async(msg)=>messages.push(msg)},config,{});
    worker.renderTemplate=async()=>({subject:'Probe',html:'<p>Probe</p>',text:'Probe'}); // Synthetic rendering only.
    await worker.process(jobs[0]); assert.equal(messages.length,1);
    pass('P6-3-worker-stale-state',{yearActive:false,pending:false,sent:1});
  }
  // P6-4: inbox write failure is swallowed by existing notification service.
  {
    const {prisma,state}=db();let inbox=0;
    const notifications=new NotificationsService({$transaction:async()=>{throw Error('inbox unavailable');},user_fcm_tokens:{findMany:async()=>[]}}, {}, {isAllowedForUser:async()=>true}, {}, undefined);
    const service=new Communications(prisma,{},notifications,config);
    assert.equal(await service.sendResult(result),'sent');assert.equal(await service.deliverPending(),0);assert.equal(inbox,0);
    pass('P6-4-inbox-loss',{dispatch:state.rows[0].status,inbox,reconciled:0});
  }
  // P6-4: persistence after delivery fails; retry produces a second actual inbox entry.
  {
    const {prisma,state}=db();let inbox=0;
    const tx={notification_logs:{create:async()=>({log_id:inbox+1})},notification_deliveries:{create:async()=>{inbox++;}}};
    const notifications=new NotificationsService({$transaction:async fn=>fn(tx),user_fcm_tokens:{findMany:async()=>[]}}, {}, {isAllowedForUser:async()=>true}, {}, undefined);
    const service=new Communications(prisma,{},notifications,config);state.failSent=true;
    assert.equal(await service.sendResult(result),'failed');assert.equal(inbox,1);
    assert.equal(await service.deliverPending(),1);assert.equal(inbox,2);
    pass('P6-4-inbox-duplicate',{inbox,dispatch:state.rows[0].status,rows:state.rows.length});
  }
  console.log('REPRODUCED '+passed.length+' scenarios (synthetic infrastructure, real runtime methods)');
})().catch(e=>{console.error(e);process.exitCode=1;}).finally(()=>{global.Date=RealDate;});
