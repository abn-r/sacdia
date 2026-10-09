// Independent service-level inventory probe: no HTTP, database or notifications.
const path = require('node:path');
const assert = require('node:assert/strict');
require(path.join(process.cwd(), 'node_modules/ts-node')).register({transpileOnly:true,skipProject:true,compilerOptions:{module:'CommonJS',moduleResolution:'Node',target:'ES2022',experimentalDecorators:true,emitDecoratorMetadata:true,esModuleInterop:true,ignoreDeprecations:'6.0'}});
require(path.join(process.cwd(),'node_modules/reflect-metadata'));
const {ValidationService} = require(path.join(process.cwd(),'src/validation/validation.service.ts'));
let row = {enrollment_id:42,user_id:'member',investiture_status:'IN_PROGRESS',locked_for_validation:false};
const history=[],logs=[];
const tx={enrollments:{update:async({data})=>(row={...row,...data})},investiture_validation_history:{create:async({data})=>history.push(data)},validation_logs:{create:async({data})=>logs.push(data)}};
const db={...tx,enrollments:{...tx.enrollments,findUnique:async()=>row},club_role_assignments:{findFirst:async()=>null},$transaction:async callback=>callback(tx)};
let honorCalls=0;
const service=new ValidationService(db,{notifySafe:async()=>{}},{approve:async()=>{honorCalls++;return 'honor';}});
(async()=>{
 await service.submitForReview('class',42,'member');
 assert.equal(row.investiture_status,'SUBMITTED_FOR_VALIDATION');assert.equal(row.locked_for_validation,true);
 console.log('PASS /validation class submit -> SUBMITTED_FOR_VALIDATION, locked=true');
 await service.review('class',42,'approved','reviewer');
 assert.equal(row.investiture_status,'APPROVED');assert.equal(row.locked_for_validation,true);
 console.log('PASS /validation class approved -> APPROVED, locked=true');
 row={...row,investiture_status:'SUBMITTED_FOR_VALIDATION'};
 await service.review('class',42,'rejected','reviewer','incomplete');
 assert.equal(row.investiture_status,'IN_PROGRESS');assert.equal(row.locked_for_validation,false);
 assert.equal(history.length,3);assert.equal(logs.length,3);
 console.log('PASS /validation class rejected -> IN_PROGRESS, locked=false; both histories receive writes');
 await service.review('honor',42,'approved','reviewer');assert.equal(honorCalls,1);
 console.log('PASS honor approval delegates separately; whole-module shutdown would exceed class scope');
})().catch(error=>{console.error(error);process.exitCode=1;});
