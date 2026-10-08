// Real Prisma/PG + real stagePresentation. Only the temporary DB provisioned by runner.
const path=require('node:path'),assert=require('node:assert/strict');
const root=process.cwd();
require(path.join(root,'node_modules/ts-node')).register({transpileOnly:true,skipProject:true,compilerOptions:{module:'CommonJS',moduleResolution:'Node',target:'ES2022',experimentalDecorators:true,emitDecoratorMetadata:true,esModuleInterop:true,jsx:'react',ignoreDeprecations:'6.0'}});
require(path.join(root,'node_modules/reflect-metadata'));
const {PrismaClient}=require(path.join(root,'node_modules/@prisma/client'));
const {PrismaPg}=require(path.join(root,'node_modules/@prisma/adapter-pg'));
const {InvestitureCommunicationsService}=require(path.join(root,'src/investiture-requests/investiture-communications.service.ts'));
const url=process.env.SACDIA_TEST_DATABASE_URL;
assert(url && new URL(url).hostname==='127.0.0.1' && new URL(url).pathname==='/sacdia_p6r1_review_test');
const db=new PrismaClient({adapter:new PrismaPg({connectionString:url})});
const service=new InvestitureCommunicationsService(db,{}, {},{get:()=>''});
(async()=>{
  await db.$executeRawUnsafe('CREATE TABLE review_operation_marker (id integer PRIMARY KEY)');
  const req1='99999999-9999-4999-8999-999999999991',req2='99999999-9999-4999-8999-999999999992';
  await db.$transaction(async tx=>{
    await tx.$executeRawUnsafe('INSERT INTO review_operation_marker VALUES(1)');
    await service.stagePresentation(tx,{requestId:req1,enrollmentIds:[7654321]});
  });
  let error=null;
  try {
    await db.$transaction(async tx=>{
      await tx.$executeRawUnsafe('INSERT INTO review_operation_marker VALUES(2)');
      await service.stagePresentation(tx,{requestId:req2,enrollmentIds:[7654321]});
    });
  } catch(e){error={code:e.code,message:e.message};}
  const markers=await db.$queryRawUnsafe('SELECT id FROM review_operation_marker ORDER BY id');
  const rows=await db.investiture_message_dispatches.findMany({where:{role:'intent',payload:{path:['enrollmentIds'],equals:[7654321]}}});
  console.log(JSON.stringify({scenario:'re-present-same-enrollment',error,markers,intents:rows.map(r=>({execution:r.execution_key,requestId:r.payload.requestId}))}));
  assert.deepEqual(markers,[{id:1}]); // second business write is rolled back despite caught P2002
  assert.equal(rows.length,1);
  console.log('REPRODUCED: second transaction did not persist; same enrollment collides across requests.');
  const user=await db.users.findFirst({select:{user_id:true}});assert(user);
  let fail=true;let pushes=0;
  const injected=new Proxy(db,{get(target,key){
    if(key==='investiture_message_dispatches')return new Proxy(target[key],{get(delegate,method){
      if(method==='updateMany')return async args=>{if(fail && args.data.status==='sent'){fail=false;throw Error('ack injected');}return delegate.updateMany(args);};
      const value=delegate[method];return typeof value==='function'?value.bind(delegate):value;
    }});
    const value=target[key];return typeof value==='function'?value.bind(target):value;
  }});
  const inboxService=new InvestitureCommunicationsService(injected,{}, {pushBestEffort:async()=>{pushes++;}},{get:()=>''});
  const draft={kind:'RESULT',executionKey:'p6r1-inbox',recipientUserId:user.user_id,role:'person',scopeKey:'user:'+user.user_id,title:'Review',body:'Review',source:'investiture:invested',requestId:req1};
  assert.equal(await inboxService.sendResult(draft),'failed');
  await Promise.all([inboxService.sendResult(draft),inboxService.sendResult(draft)]);
  const dispatch=await db.investiture_message_dispatches.findFirst({where:{execution_key:'p6r1-inbox'}});
  const logs=await db.notification_logs.findMany({where:{idempotency_key:'investiture-result:'+dispatch.dispatch_id},include:{deliveries:true}});
  assert.equal(logs.length,1);assert.equal(logs[0].deliveries.length,1);assert.equal(dispatch.status,'sent');
  console.log(JSON.stringify({scenario:'P6-4-inbox-real-postgres',logs:logs.length,deliveries:logs[0].deliveries.length,status:dispatch.status,pushCalls:pushes}));
})().catch(e=>{console.error(e);process.exitCode=1;}).finally(()=>db.$disconnect());
