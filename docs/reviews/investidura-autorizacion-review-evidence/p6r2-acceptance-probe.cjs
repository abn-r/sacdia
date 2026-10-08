// Independent assertions on real runtime. Reuses only synthetic world fixture; no fixture tests executed.
const path=require('node:path'),assert=require('node:assert/strict');const root=process.cwd();
require(path.join(root,'node_modules/ts-node')).register({transpileOnly:true,skipProject:true,compilerOptions:{module:'CommonJS',moduleResolution:'Node',target:'ES2022',experimentalDecorators:true,emitDecoratorMetadata:true,esModuleInterop:true,jsx:'react',ignoreDeprecations:'6.0'}});
require(path.join(root,'node_modules/reflect-metadata'));
const previousDescribe=global.describe;global.describe=()=>{};
const {world}=require(path.join(root,'src/investiture-requests/investiture-communications.delivery.spec.ts'));global.describe=previousDescribe;
const {InvestitureCommunicationsService:Service}=require(path.join(root,'src/investiture-requests/investiture-communications.service.ts'));
const {EmailProcessor}=require(path.join(root,'src/common/email/email.processor.ts'));
const {deliverOnce}=require(path.join(root,'src/investiture-requests/investiture-dispatch.ts'));
const {NotificationPreferencesService}=require(path.join(root,'src/notifications/notification-preferences.service.ts'));
const realDate=Date;let current=new realDate('2026-10-05T16:00:00Z');global.Date=class extends realDate{constructor(...args){super(...(args.length?args:[current.getTime()]));}static now(){return current.getTime();}};
const R='99999999-9999-4999-8999-999999999999',P='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',PA='11111111-1111-4111-8111-111111111111',B='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const cfg={get:()=> 'https://admin.example.test'};process.env.EMAIL_ENABLED='true';
function setup(){const w=world();w.state.extraPastor=false;w.state.includeOfficer=false;const jobs=[];const email={sendInvestitureNotice:async data=>{jobs.push({name:'email.investiture-notice',data,attemptsMade:0,opts:{attempts:5}});},inspectInvestitureJob:async()=> 'busy'};const service=new Service(w.prisma,email,{pushBestEffort:async()=>{}},cfg);return {...w,jobs,email,service};}
function worker(service,send){const processor=new EmailProcessor({send},cfg,{}, {get:()=>service});processor.renderTemplate=async(_name,data)=>({subject:data.subject,html:JSON.stringify(data.paragraphs),text:JSON.stringify(data.paragraphs)});return processor;}
let count=0;const done=(name,detail={})=>{count++;console.log(JSON.stringify({name,...detail}));};
(async()=>{
  {
    const w=setup();w.state.failRequestRead=true;
    await w.service.recordPresentation({requestId:R,enrollmentIds:[1]});assert.equal(w.dispatches.length,1);assert.equal(w.jobs.length,0);
    w.state.failRequestRead=false;await w.service.deliverPending(current);await w.service.deliverPending(current);
    assert.equal(w.jobs.length,1);done('PASS P6-1 basic durable intent recovery');
  }
  for(const change of ['pastor','field','year','pending']){
    const w=setup();if(change==='field')w.state.includeOfficer=true;
    await w.service.dispatchReminders(current);
    const target=w.dispatches.find(x=>x.role===(change==='field'?'director-lf':'pastor'));
    if(change==='pastor')w.state.pastorActive=false;if(change==='field')w.state.officerFieldId=20;if(change==='year')w.state.yearActive=false;if(change==='pending')w.state.pending=false;
    let sent=0;await worker(w.service,async()=>{sent++;return {messageId:'fake'};}).process(w.jobs.find(x=>x.data.dispatchId===target.dispatch_id));
    assert.equal(sent,0);assert.equal(target.status,'skipped');done('PASS P6-3 worker revalidates '+change);
  }
  {
    const w=setup();await w.service.dispatchReminders(current);const target=w.dispatches.find(x=>x.role==='pastor');
    const fresh=await w.service.prepare(target.dispatch_id);assert(!fresh.paragraphs.some(x=>x.includes('ventana de autorización está cerrada')));
    w.state.window={start_date:new Date('2026-10-01'),end_date:new Date('2026-10-03')};assert((await w.service.prepare(target.dispatch_id)).paragraphs.some(x=>x.includes('ventana de autorización está cerrada')));
    w.state.window=null;current=new realDate('2026-02-15T16:00:00Z');w.prisma.ecclesiastical_years.findMany=async()=>[{year_id:1,active:true,start_date:new Date('2026-01-01'),end_date:new Date('2026-06-30')}];
    assert((await w.service.prepare(target.dispatch_id)).paragraphs.some(x=>x.includes('ventana de autorización está cerrada')));current=new realDate('2026-10-05T16:00:00Z');
    done('PASS P6-5 default/explicit/W1 shared predicate');
  }
  {
    const w=setup();w.state.personStatus='INVESTED';
    const prefs=new NotificationPreferencesService({notification_preferences:{findUnique:async()=>({enabled:false})}},{getSettingsMap:async()=>({approvals:{mobileEnabled:true,defaultEnabled:true}})});
    const service=new Service(w.prisma,w.email,{pushBestEffort:async()=>{throw Error('must not push');}},cfg,prefs);
    await service.recordResults({requestId:R,actorId:PA,investedIds:[P],rejectedPersonIds:[],rejectedSystemIds:[]});await service.deliverPending(current);
    assert.equal(w.deliveries.length,0);done('PASS P6-4 approvals opt-out actual preferences service');
  }
  {
    const w=setup();w.state.personStatus='INVESTED';w.state.failInbox=true;
    await w.service.recordResults({requestId:R,actorId:PA,investedIds:[P],rejectedPersonIds:[],rejectedSystemIds:[]});assert.equal(w.deliveries.length,0);
    w.state.failInbox=false;w.state.failSentAck=true;await w.service.deliverPending(current);const first=w.deliveries.length;
    await Promise.all([w.service.deliverPending(current),w.service.deliverPending(current)]);assert.equal(first,2);assert.equal(w.deliveries.length,2);done('PASS P6-4 failed inbox/ack/concurrent retry', {deliveries:2});
  }
  {
    const w=setup();await w.service.dispatchReminders(current);const row=w.dispatches.find(x=>x.role==='pastor');
    row.status='sending';row.lease_until=new Date(Date.now()-1);w.email.inspectInvestitureJob=async()=> 'missing';w.jobs.length=0;
    await w.service.deliverPending(current);assert.equal(w.jobs.length,1);assert.equal(row.status,'queued');done('PASS P6-2 expired claim recovered');
  }
  // Materialization resumes after second recipient insert fails. Membership changes; key must not change.
  {
    const w=setup();w.state.includeOfficer=true;
    const original=w.prisma.investiture_authorization_people.findMany;
    w.prisma.investiture_authorization_people.findMany=async args=>{
      const rows=await original({where:{}});const ana=rows[0];
      const people=[ana,{...ana,person_id:B,user_id:B,enrollment_id:2,status:'PENDING'}];
      return people.filter(p=>!args.where.status||p.status===args.where.status);
    };
    const create=w.prisma.investiture_message_dispatches.create;let fail=true;
    w.prisma.investiture_message_dispatches.create=async args=>{if(fail&&args.data.role==='director-lf'){fail=false;throw Error('second recipient insert failed');}return create(args);};
    await w.service.recordPresentation({requestId:R,enrollmentIds:[1,2]});assert.equal(w.jobs.length,1);
    const accepted=[];const processor=worker(w.service,async payload=>{accepted.push(payload);return {messageId:'accepted-'+accepted.length};});
    await processor.process(w.jobs[0]);w.state.personStatus='INVESTED';
    await w.service.deliverPending(current);
    for(const job of w.jobs.slice(1))await processor.process(job);
    const pastor=w.dispatches.filter(x=>x.role==='pastor');assert.equal(pastor.length,1);
    const pastorMails=accepted.filter(x=>x.to.startsWith('11111111'));assert.equal(pastorMails.length,1);
    done('PASS P6-1 partial recovery keeps one pastor dispatch',{pastorDispatches:1,pastorMessages:1});
  }
  // Provider model enforces documented same-key/same-payload rule; no Resend network.
  {
    const w=setup();await w.service.dispatchReminders(current);const accepted=new Map();let ackFails=true;
    const ack=w.service.acknowledge.bind(w.service);w.service.acknowledge=async(...args)=>{if(ackFails){ackFails=false;throw Error('ack lost');}return ack(...args);};
    const processor=worker(w.service,async payload=>{const key=payload.idempotencyKey;const bytes=JSON.stringify(payload);if(accepted.has(key)&&accepted.get(key)!==bytes)throw Error('invalid_idempotent_request');accepted.set(key,bytes);return {messageId:'accepted'};});
    await assert.rejects(processor.process(w.jobs[0]),/ack lost/);
    w.state.window={start_date:new Date('2026-10-01'),end_date:new Date('2026-10-03')};
    await processor.process(w.jobs[0]);
    assert.equal(accepted.size,1);const row=w.dispatches.find(x=>x.role==='pastor');assert.equal(row.status,'sent');
    done('PASS P6-2 frozen payload under same provider key',{accepted:1,status:row.status});
  }
  // Simulated documented 24-hour provider retention; not an actual Resend request.
  {
    const w=setup();await w.service.dispatchReminders(current);let acceptedAt=null;let messages=0;let fail=true;
    const ack=w.service.acknowledge.bind(w.service);w.service.acknowledge=async(...args)=>{if(fail){fail=false;throw Error('ack lost');}return ack(...args);};
    const processor=worker(w.service,async()=>{if(acceptedAt===null||Date.now()-acceptedAt>=24*3600*1000){messages++;acceptedAt=Date.now();}return {messageId:'message-'+messages};});
    await assert.rejects(processor.process(w.jobs[0]),/ack lost/);current=new realDate(current.getTime()+25*3600*1000);
    await processor.process(w.jobs[0]);assert.equal(messages,1);assert.equal(w.dispatches.find(x=>x.role==='pastor').status,'uncertain');
    done('PASS P6-2 ambiguous delivery quarantined after provider retention',{messages,localStatus:w.dispatches.find(x=>x.role==='pastor').status});
  }

  current=new realDate('2026-10-05T16:00:00Z');
  // Revalidation must also hold after an attempted send, not only before the first attempt.
  for(const change of ['pastor','field','year','pending']){
    const w=setup();if(change==='field')w.state.includeOfficer=true;
    await w.service.dispatchReminders(current);
    const target=w.dispatches.find(x=>x.role===(change==='field'?'director-lf':'pastor'));
    const job=w.jobs.find(x=>x.data.dispatchId===target.dispatch_id);
    let calls=0,accepted=0;
    const processor=worker(w.service,async()=>{calls++;if(calls===1)throw Error('provider unavailable before accept');accepted++;return {messageId:'stale-accepted'};});
    await assert.rejects(processor.process(job),/provider unavailable/);
    if(change==='pastor')w.state.pastorActive=false;if(change==='field')w.state.officerFieldId=20;if(change==='year')w.state.yearActive=false;if(change==='pending')w.state.pending=false;
    await processor.process(job);
    assert.equal(accepted,1);assert.equal(target.status,'sent');
    done('REPRODUCED P6-3 frozen retry bypasses '+change,{calls,accepted,status:target.status});
  }
  console.log('FINISHED '+count+' scenarios: acceptance cases plus residual reproductions; fake DB/provider and renderer, real runtime methods.');
})().catch(e=>{console.error(e);process.exitCode=1;}).finally(()=>{global.Date=realDate;});
