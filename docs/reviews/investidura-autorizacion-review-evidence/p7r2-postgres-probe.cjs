// Independent review, exclusively on the fresh loopback database provisioned by p7r2-postgres-run.sh.
const path=require('node:path'),assert=require('node:assert/strict'),{randomUUID}=require('node:crypto');const root=process.cwd();
require(path.join(root,'node_modules/ts-node')).register({transpileOnly:true,skipProject:true,compilerOptions:{module:'CommonJS',moduleResolution:'Node',target:'ES2022',experimentalDecorators:true,emitDecoratorMetadata:true,esModuleInterop:true,jsx:'react',ignoreDeprecations:'6.0'}});require(path.join(root,'node_modules/reflect-metadata'));
const {PrismaClient}=require(path.join(root,'node_modules/@prisma/client')),{PrismaPg}=require(path.join(root,'node_modules/@prisma/adapter-pg')),{Client}=require(path.join(root,'node_modules/pg'));
const {InvestitureAuthorizationRequestService:Requests}=require(path.join(root,'src/investiture-requests/investiture-authorization-requests.service.ts'));
const {YearEndService}=require(path.join(root,'src/year-end/year-end.service.ts'));
const {YearCutService}=require(path.join(root,'src/year-cut/year-cut.service.ts'));
const url=process.env.SACDIA_TEST_DATABASE_URL;assert(url&&new URL(url).hostname==='127.0.0.1'&&new URL(url).pathname==='/sacdia_p7r2_review_test');
const db=new PrismaClient({adapter:new PrismaPg({connectionString:url})}),lock=new Client({connectionString:url});let locked=false,work;
function board(section,year,club,type,role='director'){return {grants:{global_roles:[],direct_permissions:[],club_assignments:[{assignment_id:'test-grant',role_name:role,permissions:[],operational:true,ecclesiastical_year_id:year,status:'active',club:{club_id:club,club_name:'P4 Club'},section:{club_section_id:section,club_type_id:type},scope:{}}]},active_assignment:null};}
const RealDate=Date;
let virtualTime=RealDate.parse('2035-12-21T05:59:59Z');
class ControlledDate extends RealDate {
 constructor(...args){super(...(args.length?args:[virtualTime]));}
 static now(){return virtualTime;}
}
async function waitForLock(){
 for(let i=0;i<200;i++){
  const r=await lock.query("SELECT count(*)::int AS n FROM pg_locks WHERE locktype='advisory' AND NOT granted");
  if(r.rows[0].n>0)return;
  await new Promise(r=>setTimeout(r,10));
 }
 throw Error('no real advisory lock waiter observed');
}
(async()=>{
 await lock.connect();
 const section=await db.club_sections.findFirst({where:{club_types:{name:'Conquistadores'}},orderBy:{club_section_id:'asc'},include:{clubs:true}});assert(section);
 const cls=await db.classes.findFirst({where:{name:'Amigo P4'}});assert(cls);
 const year=await db.ecclesiastical_years.create({data:{start_date:new RealDate('2035-01-01'),end_date:new RealDate('2035-12-31'),active:true}});
 const user=randomUUID();await db.users.create({data:{user_id:user,email:'p7r2-review@example.test',name:'P7R2 Review',active:true}});
 const role=await db.roles.findFirst({where:{role_name:'member',role_category:'CLUB'}});assert(role);
 await db.club_role_assignments.create({data:{user_id:user,role_id:role.role_id,ecclesiastical_year_id:year.year_id,start_date:new RealDate('2035-01-01'),active:true,status:'active',club_section_id:section.club_section_id}});
 const enrollment=await db.enrollments.create({data:{user_id:user,class_id:cls.class_id,ecclesiastical_year_id:year.year_id,investiture_status:'IN_PROGRESS',record_kind:'OPERATIONAL',active:true}});
 let clockReads=0,stageCalls=0;
 const service=new Requests(db,{calculateForEnrollment:async()=>({investiture_eligibility:{eligible:true}})},{emitEvent:async()=>({eventLogId:0,queued:false})},{now:()=>{clockReads++;return new RealDate(virtualTime);}},{stagePresentation:async()=>{stageCalls++;throw Error("Unexpected presentation intent");},recordPresentation:async()=>{throw Error("Unexpected delivery");}});
 const auth=board(section.club_section_id,year.year_id,section.main_club_id,section.club_type_id);
 for(const boundary of ['window','year']){
  const last=boundary==='window'?'2035-12-20':'2035-12-31';
  const start=boundary==='window'?'2035-12-21T05:59:59Z':'2036-01-01T05:59:59Z';
  const key={local_field_id:section.clubs.local_field_id,ecclesiastical_year_id:year.year_id};
  await db.local_field_investiture_windows.upsert({where:{local_field_id_ecclesiastical_year_id:key},create:{...key,start_date:new RealDate('2035-10-01'),end_date:new RealDate(last),updated_by_id:user},update:{end_date:new RealDate(last)}});
  for(const method of ['present','addPeople']){
   await db.investiture_authorization_people.deleteMany({where:{user_id:user}});
   await db.investiture_authorization_requests.deleteMany({where:{ecclesiastical_year_id:year.year_id}});
   const header=method==='addPeople'?await db.investiture_authorization_requests.create({data:{club_section_id:section.club_section_id,ecclesiastical_year_id:year.year_id,created_by_id:user}}):null;
   const dispatchesBefore=await db.investiture_message_dispatches.count();
   virtualTime=RealDate.parse(start);clockReads=0;stageCalls=0;global.Date=ControlledDate;
   await lock.query('BEGIN');locked=true;
   await lock.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`investiture-authorization-section:${section.club_section_id}:${year.year_id}`]);
   // Intentionally omit optional now, exactly as the public controller does.
   work=(method==='present'?service.present(auth,user,section.club_section_id,year.year_id,last,[enrollment.enrollment_id]):service.addPeople(auth,user,header.request_id,last,[enrollment.enrollment_id])).then(value=>({value}),error=>({error}));
   await waitForLock();virtualTime+=2000;
   await lock.query('COMMIT');locked=false;
   const result=await work;global.Date=RealDate;
   assert(result.error,"operation must reject after clock crosses boundary");
   assert.equal(result.error.code,boundary==="window"?"INVESTITURE_REQUEST_WINDOW_CLOSED":"INVESTITURE_REQUEST_YEAR_CLOSED");
   const people=await db.investiture_authorization_people.findMany({where:{user_id:user}});
   assert.equal(people.length,0);assert.equal(clockReads,2);assert.equal(stageCalls,0);
   assert.equal(await db.investiture_message_dispatches.count(),dispatchesBefore);
   console.log(JSON.stringify({scenario:'PASS P7-1 fresh clock after actual PG lock wait',method,boundary,entry:start,afterWait:new RealDate(virtualTime).toISOString(),error:result.error.code,people:people.length,stageCalls,dispatchDelta:0,clockReads,actualPgWait:true}));
  }
 }
})().catch(e=>{console.error(e);process.exitCode=1;}).finally(async()=>{global.Date=RealDate;if(locked)await lock.query('ROLLBACK').catch(()=>{});if(work)await work;await lock.end();await db.$disconnect();});
