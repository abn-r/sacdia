import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {Presentation, PresentationFile} from '@oai/artifact-tool';
const W=path.resolve(import.meta.dirname,'..');
const T=import.meta.dirname;
const S='/Users/abner/.codex/plugins/cache/openai-primary-runtime/presentations/26.909.11814/skills/presentations';
const PY='/Users/abner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3';
const {resolvePresentationFont,finalizePresentation}=await import(pathToFileURL(path.join(S,'container_tools/artifact_tool_utils.mjs')).href);
const font=resolvePresentationFont({fontFamily:'Helvetica Neue'});
console.log('Font',font);
const p=Presentation.create({slideSize:{width:1280,height:720}});
const C={paper:'#F6F4EE',ink:'#183D35',body:'#33453F',muted:'#4F5E58',accent:'#8F6428',white:'#FFFFFF',line:'#C5CEC0',card:'#D4DFD2',cardLine:'#5F7A70',warm:'#EFE6D6'};
function text(s,str,x,y,w,h,size=26,color=C.body,bold=false){
 const el=s.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});
 el.text=str;el.text.style={typeface:font,fontSize:size,bold,color,autoFit:'none'};return el;
}
function slide(title,notes='',dark=false){
 const s=p.slides.add();s.background.fill=dark?C.ink:C.paper;
 text(s,title,64,48,1100,88,42,dark?C.white:C.ink,true);
 text(s,String(p.slides.items.length).padStart(2,'0'),1188,668,48,28,16,dark?'#C4D3CA':C.muted);
 s.speakerNotes.textFrame.setText(notes);return s;
}
function note(s,str,dark=false){text(s,str,64,628,1080,36,20,dark?'#C4D3CA':C.muted);}
function pair(s,left,right,y=188){
 s.shapes.add({geometry:'rect',position:{left:64,top:y,width:536,height:400},fill:C.card,line:{fill:C.cardLine,width:1}});
 s.shapes.add({geometry:'rect',position:{left:680,top:y,width:536,height:400},fill:C.warm,line:{fill:'#C4B089',width:1}});
 text(s,left[0],92,y+24,480,44,28,C.ink,true);text(s,left[1],92,y+80,480,292,22);
 text(s,right[0],708,y+24,480,44,28,C.ink,true);text(s,right[1],708,y+80,480,292,22);
}
function rows(s,arr,start=188,step=96){
 arr.forEach((a,i)=>{text(s,a[0],64,start+i*step,330,80,27,C.ink,true);text(s,a[1],420,start+i*step,760,80,25);});
}
function table(s,values,widths,top=195,height=350,size=24){
 const t=s.tables.add({rows:values.length,columns:values[0].length,left:64,top,width:1152,height,values,columnWidths:widths});
 t.borders.assign({fill:C.line,width:1});
 t.cells.block({row:0,column:0,rowCount:values.length,columnCount:values[0].length}).assign({textStyle:{typeface:font,fontSize:size,color:C.body},margins:{left:14,right:14,top:8,bottom:8}});
 for(let r=0;r<values.length;r++) for(let c=0;c<values[0].length;c++){
  t.getCell(r,c).fill=r===0?C.ink:(r%2===0?'#ECEFE7':C.paper);
  t.getCell(r,c).text.style={typeface:font,fontSize:size,color:r===0?C.white:C.body,bold:r===0};
 }
 return t;
}
function flow(s,labels,desc,y=210){
 const gap=64,w=(1152-gap*(labels.length-1))/labels.length;
 const nodes=labels.map((label,i)=>{
  const x=64+i*(w+gap);
  const n=s.shapes.add({geometry:'rect',position:{left:x,top:y,width:w,height:88},fill:C.card,line:{fill:C.cardLine,width:1.5}});
  n.text=label;n.text.style={typeface:font,fontSize:26,bold:true,color:C.ink,alignment:'center',verticalAlignment:'middle',autoFit:'none'};
  text(s,desc[i],x,y+108,w,140,22);return n;
 });
 for(let i=1;i<nodes.length;i++)s.shapes.connect(nodes[i-1],nodes[i],{kind:'straight',fromSide:'right',toSide:'left',line:{fill:C.accent,width:2.5},tail:{type:'triangle',width:'med',length:'med'}});
}
function cards(s,arr){
 const gap=36,w=(1152-gap)/2,h=188,start=156;
 arr.forEach((a,i)=>{
  const col=i%2,row=Math.floor(i/2);
  const x=64+col*(w+gap),y=start+row*(h+24);
  s.shapes.add({geometry:'rect',position:{left:x,top:y,width:w,height:h},fill:C.card,line:{fill:C.cardLine,width:1.5}});
  text(s,a[0],x+28,y+22,w-56,40,26,C.ink,true);
  text(s,a[1],x+28,y+70,w-56,96,21);
 });
}
function steps(s,items){
 const left=items.slice(0,4);
 const right=items.slice(4);
 const draw=(list,x0,base)=>{
  list.forEach((a,i)=>{
   const y=156+i*112;
   const n=s.shapes.add({geometry:'rect',position:{left:x0,top:y+4,width:40,height:40},fill:C.accent,line:{fill:C.accent,width:0}});
   n.text=String(base+i);
   n.text.style={typeface:font,fontSize:18,bold:true,color:C.white,alignment:'center',verticalAlignment:'middle',autoFit:'none'};
   text(s,a[0],x0+56,y,470,30,22,C.ink,true);
   text(s,a[1],x0+56,y+32,470,70,19);
  });
 };
 draw(left,64,1);draw(right,660,5);
}
const content=JSON.parse(await fs.readFile(path.join(T,'contenido-venta.json'),'utf8'));
for(const item of content){
 let s;
 if(item.kind==='cover'){
  s=p.slides.add();s.background.fill=C.ink;
  s.images.add({blob:new Uint8Array(await fs.readFile(path.join(T,'portada-bosque.png'))),contentType:'image/png',position:{left:0,top:0,width:1280,height:720},fit:'cover',alt:'Ilustración conceptual de un campamento en bosque'});
  text(s,'SACDIA',64,190,720,110,78,C.white,true);
  text(s,item.title,64,318,690,150,36,C.white);
  text(s,'Ministerio Juvenil Adventista',64,575,740,40,24,'#E4EBDD');
  s.speakerNotes.textFrame.setText(item.notes);
 }else{
  const dark=item.kind==='closing'||item.kind==='statement';
  s=slide(item.title,item.notes,dark);
  if(item.kind==='rows')rows(s,item.rows,item.start||188,item.step||96);
  if(item.kind==='pair')pair(s,item.left,item.right);
  if(item.kind==='table')table(s,item.values,item.widths,item.top||195,item.height||350,item.size||24);
  if(item.kind==='flow')flow(s,item.labels,item.desc,item.y||210);
  if(item.kind==='cards')cards(s,item.cards);
  if(item.kind==='steps')steps(s,item.items);
  if(item.kind==='closing'||item.kind==='statement'){
   text(s,item.main,64,200,1100,120,48,C.white,true);
   text(s,item.body,64,360,1100,180,26,'#DCE7DC');
  }
  if(item.note)note(s,item.note,dark);
 }
}
const candidate=path.join(T,'candidata-venta.pptx');
await(await PresentationFile.exportPptx(p)).save(candidate);
const final=path.join(W,'entrega','SACDIA-presentacion-venta-iglesia-2026-09-14.pptx');
const owners=content.flatMap((x,i)=>x.kind==='table'?[i+1]:[]);
const result=await finalizePresentation({
 workspaceDir:W,candidatePath:candidate,finalPath:final,pythonExecutable:PY,
 integrityValidatorPath:path.join(S,'container_tools/inspect_presentation_package_integrity.py'),
 layoutValidatorPath:path.join(S,'container_tools/inspect_presentation_layout_geometry.py'),
 layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit',...owners.flatMap(n=>['--require-native-table-slide',String(n)])],
 requiredNativeTableOwnerSlides:owners,
 fontPolicy:{basis:'design',families:[font]},
 verifyArtifactToolImport:true,
 receiptPath:path.join(T,'validacion-venta.json')
});
console.log(JSON.stringify(result));
for(let i=0;i<p.slides.items.length;i++){
 const sl=p.slides.items[i];
 const im=await p.export({slide:sl,format:'png',scale:1});
 await fs.writeFile(path.join(T,`venta-slide-${String(i+1).padStart(2,'0')}.png`),new Uint8Array(await im.arrayBuffer()));
}
console.log('EXPORTED',final,content.length);
