import React from 'react';
import { Search, MapPin, Globe, ChevronRight, Edit2, Plus, Users, Building, Home } from 'lucide-react';

const GeographicalHierarchy = () => {
  const unions = [
    { name: 'Greater New York Conference', location: 'Manhasset, NY, USA', districts: 18, status: 'Active Field' },
    { name: 'Northeastern Conference', location: 'Jamaica, NY, USA', districts: 24, status: 'Active Field' },
    { name: 'Southern New England', location: 'South Lancaster, MA', districts: 12, status: 'Active Field' },
    { name: 'Northern New England', location: 'Westbrook, ME', districts: 8, status: 'Inactive' },
    { name: 'New York Conference', location: 'Syracuse, NY', districts: 10, status: 'Active Field' },
  ];

  return (
    <div className="h-full flex flex-col gap-8 animate-in fade-in duration-700">
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 h-full">
        {/* Left Column: List of regions/unions */}
        <div className="lg:col-span-4 bg-[#16162c] border border-slate-800 rounded-xl flex flex-col overflow-hidden">
          <div className="p-4 border-b border-slate-800">
            <div className="relative">
              <Search className="absolute left-3 top-2.5 text-slate-500" size={16} />
              <input 
                className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-[#2b2bee] placeholder-slate-600" 
                placeholder="Search geographical units..." 
                type="text"
              />
            </div>
          </div>
          <div className="flex-1 overflow-y-auto custom-scrollbar p-3 space-y-1">
             <div className="px-3 py-2 text-[10px] font-bold text-slate-500 uppercase tracking-widest mb-2">Atlantic Union Fields</div>
             <button className="w-full text-left p-3 rounded-lg bg-[#2b2bee]/10 border border-[#2b2bee]/30 flex items-center justify-between group">
               <div className="flex items-center gap-3">
                 <div className="w-10 h-10 rounded bg-[#16162c] border border-slate-800 flex items-center justify-center text-[#2b2bee] font-bold text-xs">GNY</div>
                 <div>
                   <div className="text-sm font-bold text-white">Greater New York</div>
                   <div className="text-xs text-[#2b2bee]">18 Districts</div>
                 </div>
               </div>
               <ChevronRight size={18} className="text-[#2b2bee]" />
             </button>
             {['NEC', 'SNEC', 'NNEC', 'NY'].map(code => (
               <button key={code} className="w-full text-left p-3 rounded-lg hover:bg-slate-800/50 flex items-center gap-3 transition-colors">
                 <div className="w-10 h-10 rounded bg-[#16162c] border border-slate-800 flex items-center justify-center text-slate-500 font-bold text-xs">{code}</div>
                 <div>
                    <div className="text-sm font-medium text-slate-300">Field Unit {code}</div>
                    <div className="text-xs text-slate-500">24 Districts</div>
                 </div>
               </button>
             ))}
          </div>
          <div className="p-4 border-t border-slate-800">
            <button className="w-full py-2 flex items-center justify-center gap-2 text-sm font-medium text-slate-300 hover:text-white bg-slate-900 hover:bg-slate-800 rounded-lg border border-slate-800 transition-all">
              <Plus size={16} />
              New Unit
            </button>
          </div>
        </div>

        {/* Right Column: Detailed View */}
        <div className="lg:col-span-8 space-y-8 overflow-y-auto custom-scrollbar pr-1">
          <div className="bg-[#16162c] border border-slate-800 rounded-xl p-6 shadow-xl relative overflow-hidden">
            <div className="absolute top-0 right-0 p-32 bg-[#2b2bee]/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 relative z-10">
              <div className="flex items-start gap-5">
                <div className="w-20 h-20 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-center text-slate-600 shadow-inner">
                  <Building size={40} />
                </div>
                <div>
                  <h1 className="text-2xl font-bold text-white mb-1 tracking-tight">Greater New York Conference</h1>
                  <div className="flex flex-col gap-1 text-sm text-slate-400 mt-2">
                    <div className="flex items-center gap-2">
                      <MapPin size={16} className="text-[#2b2bee]" />
                      <span>Manhasset, NY, USA</span>
                    </div>
                    <div className="flex items-center gap-4 mt-1">
                      <div className="flex items-center gap-2">
                         <Globe size={16} className="text-slate-500" />
                         <span>Atlantic Union</span>
                      </div>
                      <span className="w-1 h-1 rounded-full bg-slate-600"></span>
                      <span className="font-mono text-xs">TAG: GNYC</span>
                    </div>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <button className="px-4 py-2 text-sm font-medium text-slate-300 hover:text-white bg-slate-900 border border-slate-800 rounded-lg transition-colors">Edit Details</button>
                <div className="h-8 w-px bg-slate-800"></div>
                <div className="text-right">
                   <div className="text-[10px] text-slate-500 uppercase tracking-widest font-bold">Status</div>
                   <div className="flex items-center gap-2 mt-0.5">
                     <span className="w-2 h-2 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.5)]"></span>
                     <span className="text-sm font-bold text-green-400">Active Field</span>
                   </div>
                </div>
              </div>
            </div>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-white">Districts <span className="text-sm font-normal text-slate-500 ml-2">within Greater New York</span></h2>
              <button className="bg-[#2b2bee] hover:bg-[#1e1ebd] text-white px-4 py-2 rounded-lg text-sm font-medium shadow-lg shadow-[#2b2bee]/20 flex items-center gap-2">
                <Plus size={16} />
                New District
              </button>
            </div>
            
            <div className="bg-[#16162c] border border-slate-800 rounded-xl overflow-hidden shadow-sm">
               <table className="w-full text-left text-sm">
                 <thead>
                   <tr className="bg-slate-900/50 text-slate-500 border-b border-slate-800">
                     <th className="px-6 py-4 font-bold uppercase text-[10px] tracking-widest">District Name</th>
                     <th className="px-6 py-4 font-bold uppercase text-[10px] tracking-widest">Churches</th>
                     <th className="px-6 py-4 font-bold uppercase text-[10px] tracking-widest">Assigned Pastor</th>
                     <th className="px-6 py-4 font-bold uppercase text-[10px] tracking-widest">Status</th>
                     <th className="px-6 py-4 text-right"></th>
                   </tr>
                 </thead>
                 <tbody className="divide-y divide-slate-800">
                   {unions.map((u, i) => (
                     <tr key={i} className="hover:bg-slate-800/30 transition-colors group">
                       <td className="px-6 py-4 font-medium text-white">
                         <div>{u.name.split(' ')[0]} {i + 1}</div>
                         <div className="text-[10px] text-slate-500 font-mono mt-0.5">CODE: DIST-0{i+1}</div>
                       </td>
                       <td className="px-6 py-4">
                         <div className="flex items-center gap-2 text-slate-400">
                           <Home size={14} />
                           <span>{u.districts} Units</span>
                         </div>
                       </td>
                       <td className="px-6 py-4 text-slate-400">Pr. John Doe</td>
                       <td className="px-6 py-4">
                         <span className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                           u.status.includes('Active') ? 'bg-green-500/10 text-green-500' : 'bg-slate-500/10 text-slate-500'
                         }`}>
                           {u.status.split(' ')[0]}
                         </span>
                       </td>
                       <td className="px-6 py-4 text-right">
                         <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                           <button className="p-1.5 hover:bg-slate-800 rounded text-slate-400 hover:text-[#2b2bee]"><Edit2 size={16} /></button>
                           <button className="p-1.5 hover:bg-slate-800 rounded text-slate-400 hover:text-white"><Search size={16} /></button>
                         </div>
                       </td>
                     </tr>
                   ))}
                 </tbody>
               </table>
               <div className="p-4 border-t border-slate-800 flex justify-between items-center text-xs text-slate-500">
                  <span>Showing 5 of 18 districts</span>
                  <div className="flex gap-2">
                    <button className="px-3 py-1 rounded bg-slate-900 border border-slate-800 text-slate-400 disabled:opacity-50">Prev</button>
                    <button className="px-3 py-1 rounded bg-slate-900 border border-slate-800 text-slate-400">Next</button>
                  </div>
               </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default GeographicalHierarchy;