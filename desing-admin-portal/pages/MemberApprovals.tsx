
import React from 'react';
import { Check, X, ArrowRight, Filter } from 'lucide-react';

const MemberApprovals = () => {
  const applicants = [
    { id: 1, name: 'Sarah Miller', role: 'Master Guide Candidate', age: 19, baptized: true, avatar: 'https://picsum.photos/seed/sarah/100/100' },
    { id: 2, name: 'James Chen', role: 'Pathfinder', age: 14, baptized: false, avatar: 'https://picsum.photos/seed/james/100/100' },
    { id: 3, name: 'Maria Garcia', role: 'Adventurer Staff', age: 24, baptized: true, avatar: 'https://picsum.photos/seed/maria/100/100' },
    { id: 4, name: 'David Kim', role: 'Pathfinder TLT', age: 17, baptized: true, avatar: 'https://picsum.photos/seed/david/100/100' },
    { id: 5, name: 'Esther M.', role: 'Master Guide', age: 22, baptized: true, avatar: 'https://picsum.photos/seed/esther/100/100' },
    { id: 6, name: 'Lucas Oliveira', role: 'Adventurer', age: 8, baptized: false, avatar: 'https://picsum.photos/seed/lucas/100/100' },
  ];

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-2xl font-bold text-white">Member Approvals</h1>
          <span className="px-2.5 py-0.5 rounded-full bg-amber-500/10 text-amber-500 text-xs font-semibold border border-amber-500/20">
            12 Pending
          </span>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm text-slate-300 hover:bg-slate-800 transition-colors">
          <Filter size={16} />
          Filter
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {applicants.map((app) => (
          <div key={app.id} className="group bg-[#16162c] border border-slate-800 rounded-xl p-6 hover:border-[#2b2bee]/50 transition-all duration-300 shadow-sm relative">
            <div className="absolute top-4 right-4">
              <span className="flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-amber-500/10 text-amber-500 border border-amber-500/20">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse"></span>
                Pending
              </span>
            </div>
            
            <div className="flex flex-col items-center text-center mt-2">
              <div className="w-20 h-20 rounded-full p-1 border-2 border-dashed border-slate-700 group-hover:border-[#2b2bee] transition-colors mb-4 overflow-hidden">
                <img src={app.avatar} alt={app.name} className="w-full h-full rounded-full object-cover" />
              </div>
              <h3 className="text-lg font-bold text-white mb-1">{app.name}</h3>
              <p className="text-[10px] text-slate-500 font-bold uppercase tracking-widest mb-6">{app.role}</p>
              
              <div className="w-full grid grid-cols-2 gap-2 mb-6">
                <div className="bg-slate-900/50 p-2 rounded-lg border border-slate-800">
                  <span className="block text-[10px] text-slate-500 uppercase mb-0.5">Age</span>
                  <span className="font-bold text-slate-200">{app.age}</span>
                </div>
                <div className="bg-slate-900/50 p-2 rounded-lg border border-slate-800">
                  <span className="block text-[10px] text-slate-500 uppercase mb-0.5">Baptized</span>
                  <span className={`font-bold ${app.baptized ? 'text-green-500' : 'text-red-500'}`}>
                    {app.baptized ? 'Yes' : 'No'}
                  </span>
                </div>
              </div>

              <div className="w-full flex gap-2">
                <button className="flex-1 h-10 flex items-center justify-center rounded-lg border border-slate-800 text-slate-400 hover:bg-red-500/10 hover:text-red-500 transition-colors">
                  <X size={20} />
                </button>
                <button className="flex-1 h-10 flex items-center justify-center rounded-lg bg-green-600 hover:bg-green-700 text-white shadow-lg shadow-green-900/20 transition-all">
                  <Check size={20} />
                </button>
              </div>
              
              <button className="mt-4 text-xs font-medium text-slate-500 hover:text-[#2b2bee] transition-colors flex items-center gap-1">
                View Full Profile <ArrowRight size={12} />
              </button>
            </div>
          </div>
        ))}
      </div>
      
      <div className="flex justify-center mt-12 pb-8">
        <button className="px-6 py-2 rounded-lg border border-slate-800 text-sm font-medium text-slate-400 hover:bg-slate-800 transition-colors">
          Load More Applicants
        </button>
      </div>
    </div>
  );
};

export default MemberApprovals;
