
import React, { useState } from 'react';
import { 
  BookOpen, 
  Plus, 
  Search, 
  Filter, 
  MoreVertical, 
  Edit2, 
  Trash2, 
  ShieldAlert,
  Layers,
  CheckCircle2,
  XCircle
} from 'lucide-react';

const PermissionsCatalog = () => {
  const [permissions, setPermissions] = useState([
    { id: 'perm_001', code: 'MEM_VIEW', name: 'View Members', module: 'Membership', risk: 'Low', status: 'Active' },
    { id: 'perm_002', code: 'MEM_EDIT', name: 'Edit Members', module: 'Membership', risk: 'Medium', status: 'Active' },
    { id: 'perm_003', code: 'FIN_EDIT', name: 'Manage Finances', module: 'Finances', risk: 'Critical', status: 'Active' },
    { id: 'perm_004', code: 'GEO_ADMIN', name: 'Hierarchy Admin', module: 'Geography', risk: 'High', status: 'Active' },
    { id: 'perm_005', code: 'SYS_LOGS', name: 'View Audit Logs', module: 'System', risk: 'High', status: 'Active' },
    { id: 'perm_006', code: 'EVT_SCORE', name: 'Live Scoring', module: 'Events', risk: 'Medium', status: 'Inactive' },
  ]);

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-6">
        <div>
          <h1 className="text-3xl font-black text-white uppercase tracking-tighter">Permissions Catalog</h1>
          <p className="text-slate-500 text-sm font-medium">Define granular system capabilities and their associated security risks.</p>
        </div>
        <button className="bg-[#2b2bee] hover:bg-[#1e1ebd] text-white px-6 py-2.5 rounded-xl font-bold flex items-center gap-2 transition-all shadow-lg shadow-[#2b2bee]/20">
          <Plus size={20} />
          Define Permission
        </button>
      </div>

      <div className="flex flex-col md:flex-row justify-between items-center gap-4 bg-[#16162c] p-4 border border-slate-800 rounded-2xl">
        <div className="relative w-full md:w-96">
           <Search className="absolute left-3 top-2.5 text-slate-500" size={18} />
           <input 
             className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm text-white focus:outline-none focus:ring-1 focus:ring-[#2b2bee]" 
             placeholder="Search by code or name..."
           />
        </div>
        <div className="flex gap-2 w-full md:w-auto">
           <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm text-slate-400 hover:text-white transition-colors">
              <Filter size={16} /> Module
           </button>
           <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm text-slate-400 hover:text-white transition-colors">
              <ShieldAlert size={16} /> Risk
           </button>
        </div>
      </div>

      <div className="bg-[#16162c] border border-slate-800 rounded-2xl overflow-hidden shadow-2xl">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="bg-slate-950/50 text-[10px] uppercase font-black tracking-widest text-slate-600 border-b border-slate-800">
              <th className="px-8 py-5">Permission Code</th>
              <th className="px-8 py-5">Display Name</th>
              <th className="px-8 py-5">Module</th>
              <th className="px-8 py-5 text-center">Security Risk</th>
              <th className="px-8 py-5">Status</th>
              <th className="px-8 py-5 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/50">
            {permissions.map((perm) => (
              <tr key={perm.id} className="group hover:bg-white/[0.02] transition-colors">
                <td className="px-8 py-6">
                   <div className="font-mono text-[11px] text-[#2b2bee] bg-[#2b2bee]/5 px-2 py-1 rounded inline-block border border-[#2b2bee]/10">
                     {perm.code}
                   </div>
                </td>
                <td className="px-8 py-6 font-bold text-white">{perm.name}</td>
                <td className="px-8 py-6">
                   <div className="flex items-center gap-2 text-slate-400">
                      <Layers size={14} />
                      <span>{perm.module}</span>
                   </div>
                </td>
                <td className="px-8 py-6 text-center">
                   <span className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-widest ${
                     perm.risk === 'Critical' ? 'bg-red-500/10 text-red-500 border border-red-500/20' :
                     perm.risk === 'High' ? 'bg-amber-500/10 text-amber-500 border border-amber-500/20' :
                     perm.risk === 'Medium' ? 'bg-blue-500/10 text-blue-500 border border-blue-500/20' :
                     'bg-green-500/10 text-green-500 border border-green-500/20'
                   }`}>
                     {perm.risk}
                   </span>
                </td>
                <td className="px-8 py-6">
                   <div className="flex items-center gap-2">
                      {perm.status === 'Active' ? <CheckCircle2 size={14} className="text-green-500" /> : <XCircle size={14} className="text-slate-600" />}
                      <span className={`text-[11px] font-bold ${perm.status === 'Active' ? 'text-green-500' : 'text-slate-600'}`}>{perm.status}</span>
                   </div>
                </td>
                <td className="px-8 py-6 text-right">
                   <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button className="p-2 bg-slate-900 hover:text-[#2b2bee] rounded-lg transition-all"><Edit2 size={16} /></button>
                      <button className="p-2 bg-slate-900 hover:text-red-500 rounded-lg transition-all"><Trash2 size={16} /></button>
                   </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="p-6 bg-slate-950/30 text-center border-t border-slate-800">
           <p className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Showing {permissions.length} total base permissions</p>
        </div>
      </div>
    </div>
  );
};

export default PermissionsCatalog;
