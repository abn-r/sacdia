// Independent review, exclusively on the fresh loopback database provisioned by p7-postgres-run.sh.
const path=require('node:path'),assert=require('node:assert/strict'),{randomUUID}=require('node:crypto');const root=process.cwd();
require(path.join(root,'node_modules/ts-node')).register({transpileOnly:true,skipProject:true,compilerOptions:{module:'CommonJS',moduleResolution:'Node',target:'ES2022',experimentalDecorators:true,emitDecoratorMetadata:true,esModuleInterop:true,jsx:'react',ignoreDeprecations:'6.0'}});require(path.join(root,'node_modules/reflect-metadata'));
const {PrismaClient}=require(path.join(root,'node_modules/@prisma/client')),{PrismaPg}=require(path.join(root,'node_modules/@prisma/adapter-pg')),{Client}=require(path.join(root,'node_modules/pg'));
const {InvestitureAuthorizationRequestService:Requests}=require(path.join(root,'src/investiture-requests/investiture-authorization-requests.service.ts'));
const {YearEndService}=require(path.join(root,'src/year-end/year-end.service.ts'));
const {YearCutService}=require(path.join(root,'src/year-cut/year-cut.service.ts'));
const url=process.env.SACDIA_TEST_DATABASE_URL;assert(url&&new URL(url).hostname==='127.0.0.1'&&new URL(url).pathname==='/sacdia_p7_review_test');
const db=new PrismaClient({adapter:new PrismaPg({connectionString:url})}),lock=new Client({connectionString:url});let locked=false,work;
function board(section,year,club,type,role='director'){return {grants:{global_roles:[],direct_permissions:[],club_assignments:[{assignment_id:'test-grant',role_name:role,permissions:[],operational:true,ecclesiastical_year_id:year,status:'active',club:{club_id:club,club_name:'P4 Club'},section:{club_section_id:section,club_type_id:type},scope:{}}]},active_assignment:null};}
(async()=>{
 await lock.connect();
 const section=await db.club_sections.findFirst({where:{club_types:{name:'Conquistadores'}},orderBy:{club_section_id:'asc'}});assert(section);
 const cls=await db.classes.findFirst({where:{name:'Amigo P4'}});assert(cls);
 const year=await db.ecclesiastical_years.create({data:{start_date:new Date('2035-01-01'),end_date:new Date('2035-12-31'),active:true}});
 const user=randomUUID();await db.users.create({data:{user_id:user,email:'p7-review@example.test',name:'P7 Review',active:true}});
 const role=await db.roles.findFirst({where:{role_name:'member',role_category:'CLUB'}});assert(role);
 await db.club_role_assignments.create({data:{user_id:user,role_id:role.role_id,ecclesiastical_year_id:year.year_id,start_date:new Date('2035-01-01'),active:true,status:'active',club_section_id:section.club_section_id}});
 const enrollment=await db.enrollments.create({data:{user_id:user,class_id:cls.class_id,ecclesiastical_year_id:year.year_id,investiture_status:'IN_PROGRESS',record_kind:'OPERATIONAL',active:true}});
 const service=new Requests(db,{calculateForEnrollment:async()=>({investiture_eligibility:{eligible:true}})},{emitEvent:async()=>({eventLogId:0,queued:false})});
 const auth=board(section.club_section_id,year.year_id,section.main_club_id,section.club_type_id);
 await lock.query('BEGIN');locked=true;
 await lock.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`investiture-authorization-section:${section.club_section_id}:${year.year_id}`]);
 work=service.present(auth,user,section.club_section_id,year.year_id,'2035-11-01',[enrollment.enrollment_id],new Date('2035-10-15T18:00:00Z')).then(value=>({value}),error=>({error}));
 let waiting=false;for(let i=0;i<160;i++){const r=await lock.query("SELECT count(*)::int AS n FROM pg_locks WHERE locktype='advisory' AND NOT granted");if(r.rows[0].n>0){waiting=true;break;}await new Promise(r=>setTimeout(r,20));}assert(waiting,'presentation must really wait on PG section lock');
 const close=new YearEndService(db,{generate:async()=>{throw Error('unexpected monthly report');}});
 const summary=await close.closeYear(year.year_id);
 assert.equal((await db.ecclesiastical_years.findUnique({where:{year_id:year.year_id}})).active,false);
 await lock.query('COMMIT');locked=false;
 const result=await work;if(result.error)throw result.error;
 const late=await db.investiture_authorization_people.findMany({where:{user_id:user,request:{ecclesiastical_year_id:year.year_id}}});
 assert.equal(late.length,1);assert.equal(late[0].status,'PENDING');
 console.log(JSON.stringify({scenario:'REPRODUCED P7-1 present commits after administrative close',actualPgLockWait:true,yearActive:false,status:late[0].status,closedCount:summary.investiturePendingClosed}));
 const repeat=await close.closeYear(year.year_id).then(()=>null,e=>e);assert(repeat);
 console.log(JSON.stringify({scenario:'P7-1 retry close cannot sweep late row',response:repeat.getResponse?.(),pending:await db.investiture_authorization_people.count({where:{user_id:user,status:'PENDING'}})}));
 // An already-completed membership transition is not itself a source of clubs to sweep.
 await db.club_role_assignments.updateMany({data:{status:'ended',active:false}});
 await db.director_succession_plans.deleteMany();await db.club_year_transitions.deleteMany();
 const next=await db.ecclesiastical_years.create({data:{start_date:new Date('2036-01-01'),end_date:new Date('2036-12-31'),active:true}});
 await db.club_year_transitions.create({data:{club_id:section.main_club_id,ecclesiastical_year_id:next.year_id,status:'completed'}});
 const cut=new YearCutService(db,{getCurrentYear:async()=>next},{},{},{},{},{});
 const cutSummary=await cut.applyCut(new Date('2036-01-02T18:00:00Z'));
 assert.equal(cutSummary.investiturePendingClosed,0);assert.equal((await db.investiture_authorization_people.findUnique({where:{person_id:late[0].person_id}})).status,'PENDING');
 console.log(JSON.stringify({scenario:'REPRODUCED P7-2 old pending alone does not select club for automatic closure',transition:'completed',summary:cutSummary,status:'PENDING'}));
 // Same person/year in a section is not enough to attribute every class to that section.
 const gm=await db.club_types.findFirst({where:{name:'Guías Mayores'}})||await db.club_types.create({data:{name:'Guías Mayores',active:true}});
 const gmSection=await db.club_sections.findFirst({where:{main_club_id:section.main_club_id,club_type_id:gm.club_type_id}})||await db.club_sections.create({data:{main_club_id:section.main_club_id,club_type_id:gm.club_type_id,active:true}});
 const gmClass=await db.classes.create({data:{name:'Guía Mayor P7',club_type_id:gm.club_type_id,minimum_age:16,min_duration_years:1,max_duration_years:2,active:true}});
 await db.club_role_assignments.create({data:{user_id:user,role_id:role.role_id,ecclesiastical_year_id:year.year_id,start_date:new Date('2035-01-01'),active:true,status:'active',club_section_id:gmSection.club_section_id}});
 await db.enrollments.create({data:{user_id:user,class_id:gmClass.class_id,ecclesiastical_year_id:year.year_id,investiture_status:'IN_PROGRESS',record_kind:'OPERATIONAL',active:true}});
 await db.enrollments.update({where:{enrollment_id:enrollment.enrollment_id},data:{cross_type_enrollment:true}});
 const book=await service.yearbook(board(gmSection.club_section_id,year.year_id,section.main_club_id,gm.club_type_id),gmSection.club_section_id);
 assert(book.entries.some(e=>e.class_id===cls.class_id));assert(book.entries.some(e=>e.class_id===gmClass.class_id));
 console.log(JSON.stringify({scenario:'REPRODUCED P7-3 GM section yearbook includes Conquistadores class',section:gmSection.club_section_id,entries:book.entries}));
 for(const roleName of ['director','secretary','secretary-treasurer']){await service.yearbook(board(gmSection.club_section_id,year.year_id,section.main_club_id,gm.club_type_id,roleName),gmSection.club_section_id);}
 await assert.rejects(service.yearbook(board(section.club_section_id,year.year_id,section.main_club_id,section.club_type_id),gmSection.club_section_id));
 await assert.rejects(service.yearbook(board(gmSection.club_section_id,year.year_id,section.main_club_id,gm.club_type_id,'deputy-director'),gmSection.club_section_id));
 console.log('PASS section/role gate rejects other section and deputy; accepts director/secretary/secretary-treasurer (synthetic authorization, real DB/service).');
})().catch(e=>{console.error(e);process.exitCode=1;}).finally(async()=>{if(locked)await lock.query('ROLLBACK').catch(()=>{});if(work)await work;await lock.end();await db.$disconnect();});
