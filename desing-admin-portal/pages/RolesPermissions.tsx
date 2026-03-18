
import React, { useState } from 'react';
import { 
  ShieldCheck, 
  Plus, 
  Search, 
  Users, 
  ChevronRight, 
  Lock, 
  Eye, 
  Edit3, 
  Trash2, 
  Info,
  CheckCircle2,
  AlertTriangle
} from 'lucide-react';

interface Permission {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
}

interface PermissionGroup {
  module: string;
  permissions: Permission[];
}

const RolesPermissions = () => {
  const [selectedRoleId, setSelectedRoleId] = useState('role-1');

  const roles = [
    { id: 'role-1', name: 'Union Administrator', level: 'Full Access', users: 5, color: 'text-red-500', bg: 'bg-red-500/10' },
    { id: 'role-2', name: 'Field Director', level: 'Regional Access', users: 24, color: 'text-[#2b2bee]', bg: 'bg-[#2b2bee]/10' },
    { id: 'role-3', name: 'Club Secretary', level: 'Club Access', users: 342, color: 'text-green-500', bg: 'bg-green-500/10' },
    { id: 'role-4', name: 'Investiture Instructor', level: 'Curriculum Only', users: 120, color: 'text-amber-500', bg: 'bg-amber-500/10' },
    { id: 'role-5', name: 'Event Logistics Staff', level: 'Event Only', users: 45, color: 'text-purple-500', bg: 'bg-purple-500/10' },
  ];

  const permissionGroups: PermissionGroup[] = [
    {
      module: 'Member Management',
      permissions: [
        { id: 'p1', name: 'View Member Directory', description: 'Can search and view basic profile information of all members.', enabled: true },
        { id: 'p2', name: 'Approve Registrations', description: 'Can approve or deny new membership applications.', enabled: true },
        { id: 'p3', name: 'Edit Sensitive Data', description: 'Can modify birth dates, baptism status and medical info.', enabled: false },
        { id: 'p4', name: 'Export Member Lists', description: 'Generate and download PDF/CSV reports of members.', enabled: true },
      ]
    },
    {
      module: 'Geographical Hierarchy',
      permissions: [
        { id: 'p5', name: 'Manage Fields & Unions', description: 'Create and edit regional organizational units.', enabled: true },
        { id: 'p6', name: 'Assign District Pastors', description: 'Modify pastoral assignments for specific districts.', enabled: false },
      ]
    },
    {
      module: 'Curriculum & Investiture',
      permissions: [
        { id: 'p7', name: 'Modify Class Requirements', description: 'Update the global curriculum for Pathfinders/Adventurers.', enabled: false },
        { id: 'p8', name: 'Verify Requirement Completion', description: 'Sign off on individual member progress.', enabled: true },
      ]
    },
    {
      module: 'Event Logistics',
      permissions: [
        { id: 'p9', name: 'Create Union Events', description: 'Post new Camporees or large scale gatherings.', enabled: true },
        { id: 'p10', name: 'Manage Site Map', description: 'Assign physical camping spots and zones.', enabled: true },
      ]
    }
  ];

  const currentRole = roles.find(r => r.id === selectedRoleId);

  return (
    <div className="h-full flex flex-col gap-8 animate-in fade-in duration-500">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold text-white mb-1">Roles & Permissions</h1>
          <p className="text-slate-500 text-sm">Control system access and define security levels for different administrative layers.</p>
        </div>
        <button className="bg-[#2b2bee] hover:bg-[#1e1ebd] text-white px-6 py-2.5 rounded-xl font-bold flex items-center gap-2 transition-all shadow-lg shadow-[#2b2bee]/20">
          <Plus size={20} />
          Create New Role
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 flex-1 overflow-hidden">
        {/* Left Column: Role List */}
        <div className="lg:col-span-4 bg-[#16162c] border border-slate-800 rounded-2xl flex flex-col overflow-hidden">
          <div className="p-4 border-b border-slate-800">
            <div className="relative">
              <Search className="absolute left-3 top-2.5 text-slate-500" size={16} />
              <input 
                className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-[#2b2bee] placeholder-slate-600 text-white" 
                placeholder="Search roles..." 
                type="text"
              />
            </div>
          </div>
          <div className="flex-1 overflow-y-auto custom-scrollbar p-3 space-y-2">
            {roles.map((role) => (
              <button 
                key={role.id}
                onClick={() => setSelectedRoleId(role.id)}
                className={`w-full text-left p-4 rounded-xl border transition-all flex items-center justify-between group ${
                  selectedRoleId === role.id 
                    ? 'bg-[#2b2bee]/10 border-[#2b2bee]/40' 
                    : 'bg-transparent border-transparent hover:bg-slate-800/50'
                }`}
              >
                <div className="flex items-center gap-4">
                  <div className={`w-10 h-10 rounded-lg ${role.bg} flex items-center justify-center ${role.color}`}>
                    <Lock size={18} />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-white mb-0.5">{role.name}</div>
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] text-slate-500 uppercase font-black tracking-widest">{role.level}</span>
                      <span className="w-1 h-1 rounded-full bg-slate-700"></span>
                      <span className="text-[10px] text-slate-400 font-bold">{role.users} Users</span>
                    </div>
                  </div>
                </div>
                <ChevronRight size={18} className={`transition-transform ${selectedRoleId === role.id ? 'text-[#2b2bee] translate-x-1' : 'text-slate-700 group-hover:text-slate-400'}`} />
              </button>
            ))}
          </div>
          <div className="p-4 bg-slate-900/30 border-t border-slate-800 text-[10px] text-slate-600 font-bold uppercase text-center tracking-widest">
            Select a role to modify its policy
          </div>
        </div>

        {/* Right Column: Permission Matrix */}
        <div className="lg:col-span-8 flex flex-col gap-6 overflow-y-auto custom-scrollbar pr-2">
          {/* Active Role Header */}
          <div className="bg-[#16162c] border border-slate-800 rounded-2xl p-6 relative overflow-hidden shrink-0 shadow-lg">
            <div className={`absolute top-0 right-0 p-24 ${currentRole?.bg} opacity-5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2`}></div>
            <div className="relative z-10 flex items-center justify-between gap-6">
              <div className="flex items-center gap-6">
                <div className={`w-16 h-16 rounded-2xl ${currentRole?.bg} border border-slate-800 flex items-center justify-center ${currentRole?.color} shadow-inner`}>
                   <ShieldCheck size={32} />
                </div>
                <div>
                   <div className="flex items-center gap-3 mb-1">
                     <h2 className="text-2xl font-black text-white">{currentRole?.name}</h2>
                     <span className={`px-2 py-0.5 rounded text-[10px] font-black uppercase ${currentRole?.color} ${currentRole?.bg}`}>Active Policy</span>
                   </div>
                   <p className="text-sm text-slate-500 max-w-lg">Defining specific capabilities for the <span className="text-white font-bold">{currentRole?.level}</span> layer across all system modules.</p>
                </div>
              </div>
              <div className="flex gap-2">
                 <button className="p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-500 hover:text-white transition-colors"><Edit3 size={18} /></button>
                 <button className="p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-500 hover:text-red-500 transition-colors"><Trash2 size={18} /></button>
              </div>
            </div>
          </div>

          {/* Permissions Matrix */}
          <div className="space-y-6">
             {permissionGroups.map((group, gIdx) => (
               <div key={gIdx} className="bg-[#16162c] border border-slate-800 rounded-2xl overflow-hidden shadow-sm">
                  <div className="px-6 py-4 bg-slate-900/50 border-b border-slate-800 flex justify-between items-center">
                     <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest flex items-center gap-2">
                        <Users size={14} className="text-[#2b2bee]" />
                        {group.module}
                     </h3>
                     <button className="text-[10px] font-black text-[#2b2bee] uppercase hover:underline">Toggle All</button>
                  </div>
                  <div className="divide-y divide-slate-800/50">
                    {group.permissions.map((perm, pIdx) => (
                      <div key={pIdx} className="px-6 py-5 flex items-start justify-between gap-6 hover:bg-white/[0.02] transition-colors group">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                             <h4 className="text-sm font-bold text-white group-hover:text-[#2b2bee] transition-colors">{perm.name}</h4>
                             {perm.name.includes('Data') && <Info size={12} className="text-amber-500" />}
                          </div>
                          <p className="text-xs text-slate-500 leading-relaxed">{perm.description}</p>
                        </div>
                        <div className="flex items-center gap-8 shrink-0">
                           {/* Visibility Toggle */}
                           <div className="flex items-center gap-6">
                              <div className="flex flex-col items-center gap-1.5">
                                 <div className={`w-11 h-6 rounded-full relative cursor-pointer transition-all duration-300 shadow-inner ${perm.enabled ? 'bg-[#2b2bee]' : 'bg-slate-700'}`}>
                                    <div className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow-lg transition-all duration-300 ${perm.enabled ? 'left-6' : 'left-1'}`}></div>
                                 </div>
                                 <span className="text-[8px] font-black uppercase text-slate-600 tracking-widest">Active</span>
                              </div>
                           </div>
                        </div>
                      </div>
                    ))}
                  </div>
               </div>
             ))}
          </div>

          {/* Warning Card */}
          <div className="bg-amber-500/5 border border-amber-500/20 rounded-2xl p-6 flex gap-4 items-start mb-8">
             <div className="p-2 bg-amber-500/10 rounded-lg text-amber-500">
                <AlertTriangle size={24} />
             </div>
             <div>
                <h4 className="text-sm font-bold text-amber-500 mb-1">Critical Permissions Warning</h4>
                <p className="text-xs text-slate-500 leading-relaxed">Some permissions selected above allow viewing of HIPAA protected data or financial records. Ensure this role is only assigned to authorized personnel according to Union policies.</p>
             </div>
          </div>

          {/* Action Footer (Sticky-like) */}
          <div className="mt-4 p-6 bg-[#16162c] border border-slate-800 rounded-2xl flex justify-between items-center shadow-xl">
             <div className="flex items-center gap-3">
                <CheckCircle2 className="text-green-500" size={20} />
                <span className="text-xs text-slate-400">All changes will be logged in the <span className="text-white font-bold">Audit Trail</span></span>
             </div>
             <div className="flex gap-3">
                <button className="px-6 py-2 border border-slate-700 text-slate-400 hover:text-white rounded-xl text-sm font-bold transition-all">Discard Changes</button>
                <button className="px-10 py-2 bg-[#2b2bee] hover:bg-[#1e1ebd] text-white rounded-xl text-sm font-bold shadow-lg shadow-[#2b2bee]/20 transition-all">Apply Security Policy</button>
             </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RolesPermissions;
