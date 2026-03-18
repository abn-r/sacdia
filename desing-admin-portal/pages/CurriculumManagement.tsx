import React, { useState } from 'react';
import { 
  Folder, 
  FileText, 
  ChevronRight, 
  ChevronDown, 
  Plus, 
  Search, 
  MoreHorizontal, 
  GripVertical, 
  CheckCircle2, 
  Info, 
  Edit3, 
  Trash2, 
  Star, 
  X,
  ClipboardCheck,
  Settings,
  Clock
} from 'lucide-react';

const CurriculumManagement = () => {
  const [selectedReq, setSelectedReq] = useState<string | null>("REQ-1042");

  const treeItems = [
    { id: 'friend', label: 'Amigo (Friend)', type: 'folder', status: 'Active', children: [
      { id: 'general', label: 'General', type: 'section', children: [
        { id: 'REQ-1042', label: 'Be 10 years old', type: 'requirement', active: true },
        { id: 'REQ-1043', label: 'Club Membership', type: 'requirement' },
      ]},
      { id: 'spiritual', label: 'Spiritual Discovery', type: 'section' }
    ]},
    { id: 'companion', label: 'Compañero (Companion)', type: 'folder', status: 'Draft' },
    { id: 'explorer', label: 'Explorador (Explorer)', type: 'folder' }
  ];

  return (
    <div className="h-full flex overflow-hidden -m-8 animate-in fade-in duration-500">
      {/* Sidebar Tree View */}
      <aside className="w-[400px] flex flex-col border-r border-slate-800 bg-[#16162c] shrink-0">
        <div className="p-6 border-b border-slate-800 space-y-4">
          <div className="flex justify-between items-center">
            <h2 className="text-lg font-bold text-white tracking-tight">Curriculum Tree</h2>
            <div className="flex gap-1 text-slate-500">
               <button className="p-1 hover:text-white"><Plus size={18} /></button>
               <button className="p-1 hover:text-white"><MoreHorizontal size={18} /></button>
            </div>
          </div>
          <div className="relative">
            <Search className="absolute left-3 top-2.5 text-slate-500" size={16} />
            <input 
              className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-[#2b2bee] placeholder-slate-600 text-white" 
              placeholder="Search requirements..." 
              type="text"
            />
          </div>
          <button className="w-full bg-[#2b2bee] hover:bg-[#1e1ebd] text-white py-2 px-4 rounded-lg text-sm font-bold flex items-center justify-center gap-2 shadow-lg shadow-[#2b2bee]/20 transition-all">
            <Plus size={16} />
            New Requirement
          </button>
        </div>

        <div className="flex-1 overflow-y-auto custom-scrollbar p-2 space-y-1">
          {treeItems.map((item) => (
            <div key={item.id} className="group">
              <div className="flex items-center gap-2 p-2 rounded-lg hover:bg-slate-800/50 cursor-pointer transition-colors">
                <GripVertical size={14} className="text-slate-600 opacity-0 group-hover:opacity-100" />
                <ChevronDown size={16} className="text-slate-500" />
                <div className={`h-6 w-6 rounded flex items-center justify-center ${item.id === 'companion' ? 'bg-purple-500/20 text-purple-400' : 'bg-[#2b2bee]/20 text-[#2b2bee]'}`}>
                  <Folder size={14} />
                </div>
                <span className="text-sm font-bold text-slate-300 flex-1">{item.label}</span>
                {item.status && (
                   <span className={`text-[8px] px-1.5 py-0.5 rounded border uppercase font-bold tracking-widest ${
                     item.status === 'Active' ? 'bg-green-500/10 text-green-500 border-green-500/20' : 'bg-amber-500/10 text-amber-500 border-amber-500/20'
                   }`}>{item.status}</span>
                )}
              </div>
              {item.children && (
                <div className="ml-8 border-l border-slate-800 space-y-1 mt-1">
                  {item.children.map(section => (
                    <div key={section.id}>
                      <div className="flex items-center gap-2 p-2 pl-4 rounded-lg hover:bg-slate-800/30 cursor-pointer text-slate-400">
                        <ChevronRight size={14} />
                        <span className="text-xs font-bold uppercase tracking-wider">{section.label}</span>
                      </div>
                      {section.children && (
                        <div className="ml-4 space-y-1 pb-2">
                           {section.children.map(req => (
                             <div 
                               key={req.id}
                               onClick={() => setSelectedReq(req.id)}
                               className={`flex items-center gap-3 p-2 pl-6 rounded-lg cursor-pointer transition-all relative ${
                                 selectedReq === req.id 
                                   ? 'bg-[#2b2bee]/10 text-[#2b2bee] border-l-2 border-[#2b2bee]' 
                                   : 'text-slate-500 hover:bg-slate-800/20'
                               }`}
                             >
                               {req.active ? <CheckCircle2 size={14} /> : <FileText size={14} />}
                               <span className="text-sm font-medium flex-1 truncate">{req.label}</span>
                               {selectedReq === req.id && <div className="w-1.5 h-1.5 rounded-full bg-[#2b2bee]"></div>}
                             </div>
                           ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
        <div className="p-3 border-t border-slate-800 text-[10px] text-slate-500 text-center font-medium uppercase tracking-widest">
           Drag items to reorder hierarchy
        </div>
      </aside>

      {/* Editor Panel */}
      <section className="flex-1 bg-[#101022] relative flex flex-col">
        {!selectedReq ? (
           <div className="flex-1 flex flex-col items-center justify-center p-12 text-center opacity-30">
              <div className="w-20 h-20 bg-slate-800 rounded-2xl flex items-center justify-center mb-4">
                 <ClipboardCheck size={40} className="text-slate-500" />
              </div>
              <h3 className="text-xl font-bold text-white mb-2">Select a Requirement</h3>
              <p className="text-slate-400 max-w-sm">Click on an item in the tree to edit its details, manage criteria, or update points values.</p>
           </div>
        ) : (
           <div className="h-full flex flex-col">
             <div className="px-8 py-6 border-b border-slate-800 flex justify-between items-start bg-[#16162c]/50">
               <div className="space-y-1">
                 <div className="flex items-center gap-2">
                   <span className="text-[10px] font-bold uppercase tracking-widest text-[#2b2bee] bg-[#2b2bee]/10 px-2 py-0.5 rounded">Requirement</span>
                   <span className="text-[10px] font-mono text-slate-500">ID: REQ-1042</span>
                 </div>
                 <h2 className="text-2xl font-bold text-white">Be 10 years old and/or in Grade 5</h2>
               </div>
               <button className="p-2 text-slate-500 hover:text-white transition-colors" onClick={() => setSelectedReq(null)}>
                 <X size={24} />
               </button>
             </div>

             <div className="flex-1 overflow-y-auto custom-scrollbar p-8 space-y-10">
                <div className="space-y-6">
                  <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest flex items-center gap-2">
                    <Info size={14} /> Basic Information
                  </h3>
                  <div className="grid grid-cols-1 gap-6">
                    <div className="space-y-1.5">
                      <label className="text-sm font-bold text-slate-400">Requirement Title</label>
                      <input 
                        className="w-full bg-slate-900 border border-slate-800 rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:ring-1 focus:ring-[#2b2bee]" 
                        value="Be 10 years old and/or in Grade 5" 
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-400">Parent Class</label>
                        <select className="w-full bg-slate-900 border border-slate-800 rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:ring-1 focus:ring-[#2b2bee]">
                          <option>Amigo (Friend)</option>
                          <option>Compañero (Companion)</option>
                        </select>
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-400">Section</label>
                        <select className="w-full bg-slate-900 border border-slate-800 rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:ring-1 focus:ring-[#2b2bee]">
                          <option>General</option>
                          <option>Spiritual Discovery</option>
                        </select>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="space-y-6">
                   <div className="flex justify-between items-center">
                     <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest flex items-center gap-2">
                       <Edit3 size={14} /> Instructions
                     </h3>
                     <button className="text-xs font-bold text-[#2b2bee] hover:underline">Preview Instructions</button>
                   </div>
                   <div className="border border-slate-800 rounded-xl overflow-hidden bg-slate-900/30">
                      <div className="bg-slate-900 border-b border-slate-800 p-2 flex gap-1">
                        {['bold', 'italic', 'list', 'link'].map(tool => (
                          <button key={tool} className="p-1.5 text-slate-500 hover:text-white hover:bg-slate-800 rounded capitalize text-[10px] font-bold tracking-wider">{tool}</button>
                        ))}
                      </div>
                      <textarea 
                        className="w-full bg-transparent p-4 text-sm text-slate-300 min-h-[120px] focus:outline-none resize-none" 
                        placeholder="Describe how to fulfill this requirement..."
                        defaultValue="Candidate must provide proof of age via birth certificate or school ID. Instructor must verify enrollment in Grade 5 if candidate is under 10 years of age."
                      />
                   </div>
                </div>

                <div className="space-y-6">
                   <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest flex items-center gap-2">
                     <Settings size={14} /> Metadata & Logic
                   </h3>
                   <div className="grid grid-cols-2 gap-6">
                      <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-400">Minimum Age</label>
                        <div className="relative">
                          <input type="number" className="w-full bg-slate-900 border border-slate-800 rounded-lg pl-10 pr-4 py-3 text-sm text-white" defaultValue={10} />
                          <Clock size={16} className="absolute left-3 top-3.5 text-slate-600" />
                        </div>
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-400">Points Value</label>
                        <div className="relative">
                          <input type="number" className="w-full bg-slate-900 border border-slate-800 rounded-lg pl-10 pr-4 py-3 text-sm text-white" defaultValue={50} />
                          <Star size={16} className="absolute left-3 top-3.5 text-slate-600" />
                        </div>
                      </div>
                   </div>
                   <div className="bg-[#16162c] rounded-xl p-4 border border-slate-800 space-y-4">
                      <div className="flex items-center justify-between">
                         <div>
                            <p className="text-sm font-bold text-white">Mandatory Requirement</p>
                            <p className="text-xs text-slate-500">Is this required to complete the class?</p>
                         </div>
                         <div className="w-10 h-5 bg-[#2b2bee] rounded-full relative">
                            <div className="absolute right-0.5 top-0.5 w-4 h-4 bg-white rounded-full shadow"></div>
                         </div>
                      </div>
                      <div className="h-px bg-slate-800"></div>
                      <div className="flex items-center justify-between">
                         <div>
                            <p className="text-sm font-bold text-white">Instructor Verify Only</p>
                            <p className="text-xs text-slate-500">Can only be marked complete by an instructor.</p>
                         </div>
                         <div className="w-10 h-5 bg-slate-700 rounded-full relative">
                            <div className="absolute left-0.5 top-0.5 w-4 h-4 bg-slate-400 rounded-full shadow"></div>
                         </div>
                      </div>
                   </div>
                </div>
             </div>

             <div className="p-6 border-t border-slate-800 bg-[#16162c] flex justify-between items-center">
                <button className="flex items-center gap-2 px-4 py-2 text-sm font-bold text-red-500 hover:bg-red-500/10 rounded-lg transition-colors">
                  <Trash2 size={18} />
                  Delete
                </button>
                <div className="flex gap-3">
                   <button className="px-6 py-2 border border-slate-700 text-slate-400 hover:text-white rounded-lg text-sm font-bold transition-all">Cancel</button>
                   <button className="px-8 py-2 bg-[#2b2bee] hover:bg-[#1e1ebd] text-white rounded-lg text-sm font-bold shadow-lg shadow-[#2b2bee]/20 transition-all">Save Changes</button>
                </div>
             </div>
           </div>
        )}
      </section>
    </div>
  );
};

export default CurriculumManagement;