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
const C={paper:'#F6F4EE',ink:'#183D35',body:'#33453F',muted:'#66746D',accent:'#B78339',white:'#FFFFFF',line:'#D7DDD4'};
function text(s,str,x,y,w,h,size=26,color=C.body,bold=false){
 const el=s.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});
 el.text=str;el.text.style={typeface:font,fontSize:size,bold,color,autoFit:'none'};return el;
}
function slide(title,notes='',dark=false){
 const s=p.slides.add();s.background.fill=dark?C.ink:C.paper;
 text(s,title,64,52,1148,105,44,dark?C.white:C.ink,true);
 text(s,String(p.slides.items.length).padStart(2,'0'),1170,655,54,28,16,dark?'#C4D3CA':C.muted);
 s.speakerNotes.textFrame.setText(notes);return s;
}
function note(s,str){text(s,str,64,602,1120,48,21,C.muted);}
function pair(s,left,right,y=235){
 text(s,left[0],64,y,500,60,30,C.ink,true);text(s,left[1],64,y+76,500,240,27);
 text(s,right[0],680,y,500,60,30,C.ink,true);text(s,right[1],680,y+76,500,240,27);
}
function rows(s,arr,start=205){
 arr.forEach((a,i)=>{text(s,a[0],64,start+i*103,295,85,28,C.ink,true);text(s,a[1],397,start+i*103,800,85,26);});
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
function flow(s,labels,desc,y=260){
 const gap=44,w=(1152-gap*(labels.length-1))/labels.length;
 const nodes=labels.map((label,i)=>{
  const x=64+i*(w+gap);
  const n=s.shapes.add({geometry:'rect',position:{left:x,top:y,width:w,height:108},fill:'#E5ECE1',line:{fill:'#86A095',width:1}});
  n.text=label;n.text.style={typeface:font,fontSize:27,bold:true,color:C.ink,alignment:'center',verticalAlignment:'middle',autoFit:'none'};
  text(s,desc[i],x,y+128,w,150,23);return n;
 });
 for(let i=1;i<nodes.length;i++)s.shapes.connect(nodes[i-1],nodes[i],{kind:'straight',fromSide:'right',toSide:'left',line:{fill:C.accent,width:2},tail:{type:'triangle',width:'med',length:'med'}});
}
const content=JSON.parse(await fs.readFile(path.join(T,'contenido.json'),'utf8'));
for(const item of content){
 let s;
 if(item.kind==='cover'){
  s=p.slides.add();s.background.fill=C.ink;
  s.images.add({blob:new Uint8Array(await fs.readFile(path.join(T,'portada-bosque.png'))),contentType:'image/png',position:{left:0,top:0,width:1280,height:720},fit:'cover',alt:'Ilustración conceptual de un campamento en bosque'});
  text(s,'SACDIA',64,190,720,110,78,C.white,true);
  text(s,item.title,68,320,690,160,36,C.white);
  text(s,'Unión Mexicana Interoceánica',68,575,740,40,24,'#E4EBDD');
  s.speakerNotes.textFrame.setText(item.notes);
 }else{
  s=slide(item.title,item.notes,item.kind==='closing');
  if(item.kind==='rows')rows(s,item.rows,item.start||205);
  if(item.kind==='pair')pair(s,item.left,item.right);
  if(item.kind==='table')table(s,item.values,item.widths,item.top||195,item.height||350,item.size||24);
  if(item.kind==='flow')flow(s,item.labels,item.desc,item.y||260);
  if(item.kind==='closing'){
   text(s,item.main,64,218,1060,170,42,C.white,true);
   text(s,item.body,64,433,1050,165,28,'#DCE7DC');
  }
  if(item.note)note(s,item.note);
 }
}
await fs.writeFile(path.join(T,'font-policy.json'),JSON.stringify({basis:'design',families:[font]},null,2));
const candidate=path.join(T,'candidata.pptx');
await(await PresentationFile.exportPptx(p)).save(candidate);
await fs.writeFile(path.join(T,'presentacion.proto.json'),JSON.stringify(p.toProto()));
const final=path.join(W,'entrega',process.env.FINAL_NAME||'SACDIA-presentacion-ejecutiva-2026-09-14.pptx');
const owners=content.flatMap((x,i)=>x.kind==='table'?[i+1]:[]);
const result=await finalizePresentation({
 workspaceDir:W,candidatePath:candidate,finalPath:final,pythonExecutable:PY,
 integrityValidatorPath:path.join(S,'container_tools/inspect_presentation_package_integrity.py'),
 layoutValidatorPath:path.join(S,'container_tools/inspect_presentation_layout_geometry.py'),
 layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit',...owners.flatMap(n=>['--require-native-table-slide',String(n)])],
 requiredNativeTableOwnerSlides:owners,
 fontPolicy:{basis:'design',families:[font]},
 verifyArtifactToolImport:true,
 receiptPath:path.join(T,'validacion.json')
});
console.log(JSON.stringify(result));
for(let i=0;i<p.slides.items.length;i++){
 const sl=p.slides.items[i];
 const im=await p.export({slide:sl,format:'png',scale:1});
 await fs.writeFile(path.join(T,`slide-${String(i+1).padStart(2,'0')}.png`),new Uint8Array(await im.arrayBuffer()));
 const layout=await sl.export({format:'layout'});await fs.writeFile(path.join(T,`slide-${i+1}.layout.json`),await layout.text());
}
console.log('EXPORTED',final,content.length);
