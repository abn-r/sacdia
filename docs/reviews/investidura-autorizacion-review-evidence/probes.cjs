const assert = require('node:assert/strict');
const root='/Users/abner/Documents/development/sacdia/sacdia-backend';
const {ClassRequirementEligibilityService}=require(root+'/src/classes/class-requirement-eligibility.service.ts');
const {CertificateBulkImportsService}=require(root+'/src/certificate-bulk-imports/certificate-bulk-imports.service.ts');
const {InstitutionalCertificateRequestsService}=require(root+'/src/certificate-bulk-imports/institutional-certificate-requests.service.ts');
const {ClassProgressScopeService}=require(root+'/src/classes/class-progress-scope.service.ts');
const year={year_id:2026,start_date:new Date('2026-01-01Z'),end_date:new Date('2026-12-31Z'),active:true};
function eligibilityDb(assignmentType) {
 const counts={}; const track=(n,fn)=>async(...args)=>{counts[n]=(counts[n]||0)+1;return fn(...args)};
 const enrollment={enrollment_id:10,user_id:'member',class_id:7,ecclesiastical_year_id:2026,classes:{class_id:7,club_type_id:2,advanced_enabled:false},ecclesiastical_year:year};
 const assignment={club_sections:{clubs:{local_field_id:30,local_fields:{local_field_id:30,union_id:20,unions:{union_id:20,division_id:1}}}}};
 const db={
  enrollments:{findUnique:track('enrollment',()=>enrollment)},
  class_sections:{findMany:track('sections',()=>[{section_id:101,requirement_track:'BASIC',required_for_investiture:true,owner_division_id:null,owner_union_id:null,owner_local_field_id:null}])},
  class_section_progress:{findMany:track('progress',()=>[{section_id:101,status:'PENDING',score:85}])},
  users_pr:{findUnique:track('users_pr',()=>({active_club_assignment_id:'gm-assignment'}))},
  club_role_assignments:{findMany:track('assignments',({where})=>where.club_sections.club_type_id===assignmentType?[assignment]:[])},
  local_field_class_thresholds:{findUnique:track('threshold',()=>({minimum_percent:90}))}
 };
 return {db,counts,enrollment};
}
(async()=>{
 const regular=eligibilityDb(2),cross=eligibilityDb(3);
 const a=await new ClassRequirementEligibilityService(regular.db).calculateForEnrollment(10);
 const b=await new ClassRequirementEligibilityService(cross.db).calculateForEnrollment(10);
 assert.equal(a.passing_score,90);assert.equal(a.investiture_eligibility.eligible,false);
 assert.equal(b.passing_score,80);assert.equal(b.investiture_eligibility.eligible,true);assert.equal(cross.counts.threshold||0,0);
 console.log('F1 REPRODUCED: Campo=90, score=85. Regular threshold=90/eligible=false; GM cross-type threshold=80/eligible=true; threshold queries=0.');
 let ageReads=0;
 const item={item_id:'item',item_type:'CLASS',class_id:1,completed_at:new Date('2026-03-01Z'),status:'READY',revision:0};
 const tx={
  certificate_bulk_import_batches:{findFirst:async()=>({batch_id:'batch',user_id:'member',status:'DRAFT',revision:0}),update:async()=>({})},
  certificate_bulk_import_items:{findFirst:async()=>({...item}),update:async({data})=>({...item,...data})},
  certificate_bulk_import_item_events:{create:async()=>({})},
  users:{findUnique:async()=>{ageReads++;return {birthday:new Date('2016-01-01Z')}}},
  classes:{findUnique:async()=>({minimum_age:10,active:true,asset_code:'CQ-01'})},
  ecclesiastical_years:{findMany:async()=>[{...year,year_id:2025,start_date:new Date('2025-01-01Z'),end_date:new Date('2025-12-31Z')}]}
 };
 const updated=await new CertificateBulkImportsService({$transaction:async cb=>cb(tx)},{}).updateItem('member','batch','item',{completed_at:'2025-06-01',expected_revision:0});
 assert.equal(updated.status,'READY');assert.equal(ageReads,0);
 console.log('F2 REPRODUCED: modifying a READY class to invalid historical year without mark_as_ready retains READY; age checks=0. Submission/approval still revalidate.');
 let birthday=new Date('1990-01-01Z'),yearReads=0,transactions=0,locks=0;
 const request={request_id:'request',user_id:'member',class_id:9,file_id:'file',status:'PENDING_REVIEW',revision:0,completed_at:new Date('2008-07-07Z'),ecclesiastical_year_id:2008,decision_reason:null,reviewed_at:null,class:{asset_code:'GM-02',name:'GM avanzado'}};
 const oldYear={...year,year_id:2008,start_date:new Date('2008-01-01Z'),end_date:new Date('2008-12-31Z')};
 const db={
  users:{findUnique:async({select})=>select.users_roles?{users_roles:[{roles:{role_name:'super-admin'}}]}:{birthday}},
  classes:{findUnique:async()=>({minimum_age:16})},
  ecclesiastical_years:{findMany:async()=>{if(++yearReads===2)birthday=new Date('2000-01-01Z');return [oldYear]}},
  institutional_certificate_requests:{findFirst:async()=>({...request}),updateMany:async({data})=>{Object.assign(request,data);return {count:1}}},
  institutional_certificate_request_events:{create:async()=>({})},
  $queryRawUnsafe:async()=>{locks++;return []},
  $transaction:async cb=>{transactions++;return cb(db)}
 };
 const approved=await new InstitutionalCertificateRequestsService(db).approve('reviewer','request',{expected_revision:0});
 assert.equal(approved.status,'APPROVED');assert.equal(transactions,0);assert.equal(birthday.getUTCFullYear(),2000);
 console.log('F3 SIMULATED INTERLEAVING: historical age initially=18, birthday changes to age=8 before write; institutional request APPROVED. Transactions=0, standalone lock statements='+locks+'.');
 const bulk=eligibilityDb(2);bulk.db.users_pr.findUnique=async()=>null;
 bulk.db.enrollments.findMany=async()=>Array.from({length:30},(_,i)=>({enrollment_id:i+1,user_id:'member-'+i,class_id:7,ecclesiastical_year_id:2026,investiture_status:'IN_PROGRESS',cross_type_enrollment:false,users:{name:'Synthetic'}}));
 const scope=new ClassProgressScopeService(bulk.db,{}, {},new ClassRequirementEligibilityService(bulk.db));
 scope.getProgressScope=async()=>({club_section_id:1,ecclesiastical_year_id:2026,access_level:'SECTION_WIDE',classes:[{class_id:7}]});
 const listing=await scope.getClassMembersProgress({actorUserId:'director',clubId:1,sectionId:1,classId:7,ecclesiasticalYearId:2026});
 assert.equal(listing.members.length,30);assert.equal(bulk.counts.sections,30);
 console.log('F4 QUERY FANOUT: 30 members -> '+JSON.stringify(bulk.counts)+' plus 30 users_pr reads and 1 list query (181 total, excluding scope resolution).');
 console.log('Actual services, synthetic in-memory DB only. No production, no DB connections, no repository changes.');
})().catch(e=>{console.error(e);process.exit(1)});
