
import React, { useState } from 'react';
import { 
  Key, 
  Plus, 
  Search, 
  Users, 
  ChevronRight, 
  ShieldCheck, 
  Edit3, 
  Trash2,
  Info,
  Clock,
  ArrowUpRight
} from 'lucide-react';

const RolesCatalog = () => {
  const [roles] = useState([
    { id: 'role_1', name: 'Union Administrator', desc: 'Highest system level with full management of fields, finances, and system settings.', users: 5, level: 1, lastModified: 'Oct 24, 2023' },
    { id: 'role_2', name: 'Field Director', desc: 'Manages all districts within a specific conference/field. Limited to regional scope.', users: 24, level: 2, lastModified: 'Oct 15, 2023' },
    { id: 'role_3', name: 'Club Secretary', desc: 'Administrative access for a single club. Manage members, classes, and local records.', users: 342, level: 3, lastModified: 'Nov 02, 2023' },
    { id: 'role_4', name: 'Parent/Guardian', desc: 'Access to child progress, investiture tracking and consent forms.', users: 1240, level: 4, lastModified: 'Nov 12, 2023' },
  ]);

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-black text-white uppercase tracking-tighter">Roles Catalog</h1>
          <p className="text-slate-500 text-sm font-medium">Define hierarchical identities and administrative scopes.</p>
        </div>
        <button className="bg-[#2b2bee] hover:bg-[#1e1ebd] text-white px-6 py-2.5 rounded-xl font-bold flex items-center gap-2 transition-all shadow-lg shadow-[#2b2bee]/20">
          <Plus size={20} />
          Add Identity Role
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {roles.map((role) => (
          <div key={role.id} className="bg-[#16162c] border border-slate-800 rounded-2xl p-6 flex flex-col group hover:border-[#2b2bee]/50 transition-all shadow-xl relative overflow-hidden">
             {/* Security Level Watermark */}
             <div className="absolute -bottom-4 -right-4 text-white/[0.03] font-black text-8xl italic select-none">
               L{role.level}
             </div>
             
             <div className="flex justify-between items-start mb-6 relative z-10">
                <div className={`w-12 h-12 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-center ${role.level === 1 ? 'text-[#2b2bee]' : 'text-slate-500'}`}>
                   <ShieldCheck size={24} />
                </div>
                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                   <button className="p-1.5 hover:text-white transition-colors"><Edit3 size={16} /></button>
                   <button className="p-1.5 hover:text-red-500 transition-colors"><Trash2 size={16} /></button>
                </div>
             </div>

             <h3 className="text-lg font-bold text-white mb-2 relative z-10">{role.name}</h3>
             <p className="text-xs text-slate-500 leading-relaxed flex-1 mb-6 relative z-10">{role.desc}</p>
             
             <div className="space-y-4 pt-4 border-t border-slate-800 relative z-10">
                <div className="flex justify-between items-center text-[10px] font-bold uppercase tracking-widest text-slate-600">
                   <span>Active Users</span>
                   <span className="text-white">{role.users}</span>
                </div>
                <div className="flex justify-between items-center text-[10px] font-bold uppercase tracking-widest text-slate-600">
                   <div className="flex items-center gap-1.5"><Clock size={12} /> Last Edit</div>
                   <span>{role.lastModified}</span>
                </div>
                <button className="w-full mt-2 py-2.5 rounded-lg bg-slate-900 border border-slate-800 text-[#2b2bee] text-xs font-bold uppercase tracking-widest hover:bg-[#2b2bee]/10 hover:border-[#2b2bee]/20 transition-all flex items-center justify-center gap-2">
                   View Permissions <ArrowUpRight size={14} />
                </button>
             </div>
          </div>
        ))}

        {/* Empty State / Add Card */}
        <button className="border-2 border-dashed border-slate-800 rounded-2xl p-6 flex flex-col items-center justify-center text-slate-600 hover:border-[#2b2bee] hover:text-[#2b2bee] transition-all group min-h-[340px]">
           <div className="w-16 h-16 rounded-full bg-slate-900 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
              <Plus size={32} />
           </div>
           <span className="font-bold uppercase tracking-widest text-xs">Define New Role</span>
        </button>
      </div>

      {/* Role Hierarchy Legend */}
      <div className="bg-blue-500/5 border border-blue-500/20 rounded-2xl p-6 flex gap-6 items-center">
         <div className="p-3 bg-blue-500/10 rounded-2xl text-[#2b2bee]">
            <Info size={28} />
         </div>
         <div>
            <h4 className="text-sm font-bold text-white mb-1">About Security Levels</h4>
            <p className="text-xs text-slate-500 leading-relaxed">Levels are used for hierarchical filtering. A user can only manage other users with a higher level number (lower priority) than their own. Level 1 (Union Admin) can manage all levels, while Level 3 (Club Secretary) can only manage Level 4 (Parents/Members).</p>
         </div>
      </div>
    </div>
  );
};

export default RolesCatalog;
