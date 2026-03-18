
import React from 'react';
import { 
  Plus, 
  MoreHorizontal, 
  Search, 
  Filter, 
  Users, 
  Mail, 
  CheckCircle2, 
  Calendar,
  Grid
} from 'lucide-react';

const ClubMembers = () => {
  const members = [
    { name: 'Sarah Jenkins', role: 'Director', class: 'Master Guide', joined: 'Since 2020', status: 'Active', avatar: 'https://picsum.photos/seed/jenk/32/32', email: 'sarah.j@example.com' },
    { name: 'David Kim', role: 'Counselor', class: 'Voyager', joined: 'Unit: Eagles', status: 'Active', avatar: 'https://picsum.photos/seed/dkim/32/32', email: 'dkim88@example.com' },
    { name: 'Elena Rodriguez', role: 'Pathfinder', class: 'Friend', joined: 'Unit: Doves', status: 'Active', avatar: 'https://picsum.photos/seed/elena/32/32', email: 'elena.r@example.com' },
    { name: 'Marcus Johnson', role: 'Pathfinder', class: 'Ranger', joined: 'Unit: Bears', status: 'Inactive', avatar: 'https://picsum.photos/seed/marcus/32/32', email: 'marcus.j@example.com' },
    { name: 'Angela Bass', role: 'Instructor', class: 'Master Guide', joined: 'Drill & Marching', status: 'Active', avatar: 'https://picsum.photos/seed/angela/32/32', email: 'angela.b@example.com' },
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div className="flex items-start gap-5">
           <div className="w-16 h-16 rounded-xl bg-gradient-to-tr from-[#2b2bee] to-indigo-900 flex items-center justify-center text-white shadow-lg">
             <Users size={32} />
           </div>
           <div>
             <h1 className="text-3xl font-bold text-white mb-1 tracking-tight">Club Orion</h1>
             <div className="flex items-center gap-3 text-sm text-slate-500">
               <span className="font-medium text-slate-400">Pathfinder Club</span>
               <span className="w-1 h-1 rounded-full bg-slate-700"></span>
               <span>Northern Conference</span>
               <span className="w-1 h-1 rounded-full bg-slate-700"></span>
               <span className="font-mono text-xs">ID: #88291</span>
             </div>
             <div className="flex items-center gap-4 mt-2 text-xs">
               <span className="flex items-center gap-1.5 text-slate-400"><Users size={12} /> 42 Members</span>
               <span className="flex items-center gap-1.5 text-slate-400"><Calendar size={12} /> Established 2018</span>
             </div>
           </div>
        </div>
        <div className="flex items-center gap-3">
          <button className="flex items-center justify-center px-4 py-2 border border-slate-800 text-slate-300 hover:text-white rounded-lg text-sm font-medium transition-colors">
            Edit Club
          </button>
          <button className="flex items-center justify-center gap-2 px-4 py-2 bg-[#2b2bee] hover:bg-[#1e1ebd] text-white rounded-lg text-sm font-medium shadow-lg shadow-[#2b2bee]/20 transition-all">
            <Plus size={18} />
            Add Member
          </button>
        </div>
      </div>

      <div className="flex items-center gap-8 border-b border-slate-800 pb-1">
        {['General', 'Instances', 'Members', 'Finances', 'Reports'].map((tab) => (
          <button key={tab} className={`pb-3 text-sm font-medium transition-colors relative ${tab === 'Members' ? 'text-white' : 'text-slate-500 hover:text-slate-300'}`}>
            {tab}
            {tab === 'Members' && <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#2b2bee]"></div>}
          </button>
        ))}
      </div>

      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-64">
            <Search className="absolute left-3 top-2.5 text-slate-500" size={18} />
            <input 
              className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-[#2b2bee] placeholder-slate-600" 
              placeholder="Filter members..." 
              type="text"
            />
          </div>
          <button className="flex items-center gap-2 px-3 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm text-slate-400 hover:text-white">
            <Filter size={16} /> Role
          </button>
          <button className="flex items-center gap-2 px-3 py-2 bg-slate-900 border border-slate-800 rounded-lg text-sm text-slate-400 hover:text-white">
            <Filter size={16} /> Class
          </button>
        </div>
        <div className="flex items-center gap-4">
          <span className="text-sm text-slate-500">Showing <span className="font-bold text-white">1-10</span> of <span className="font-bold text-white">42</span></span>
          <button className="p-2 bg-slate-900 border border-slate-800 rounded-lg text-slate-500 hover:text-white">
            <Grid size={18} />
          </button>
        </div>
      </div>

      <div className="bg-[#16162c] border border-slate-800 rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-900/50 text-slate-500 text-[10px] uppercase font-bold tracking-widest border-b border-slate-800">
                <th className="px-6 py-4 w-12"><input type="checkbox" className="rounded bg-slate-800 border-slate-700" /></th>
                <th className="px-6 py-4">Member</th>
                <th className="px-6 py-4">Role</th>
                <th className="px-6 py-4">Class</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4 text-right"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {members.map((m, i) => (
                <tr key={i} className="hover:bg-slate-800/20 transition-colors group">
                  <td className="px-6 py-4"><input type="checkbox" className="rounded bg-slate-800 border-slate-700" /></td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <img src={m.avatar} alt={m.name} className="w-10 h-10 rounded-full border border-slate-800" />
                      <div>
                        <div className="text-sm font-bold text-white">{m.name}</div>
                        <div className="text-[10px] text-slate-500">{m.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="px-2 py-1 bg-slate-800 text-slate-300 rounded-md text-[10px] font-bold uppercase tracking-wide border border-slate-700 group-hover:border-[#2b2bee]/40">
                      {m.role}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm font-medium text-slate-300">{m.class}</div>
                    <div className="text-[10px] text-slate-500">{m.joined}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                       <div className={`w-2 h-2 rounded-full ${m.status === 'Active' ? 'bg-green-500' : 'bg-slate-600'}`}></div>
                       <span className={`text-sm font-medium ${m.status === 'Active' ? 'text-green-500' : 'text-slate-500'}`}>
                         {m.status}
                       </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button className="text-slate-500 hover:text-white transition-colors">
                      <MoreHorizontal size={18} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="px-6 py-4 bg-slate-900/30 border-t border-slate-800 flex justify-between items-center">
          <span className="text-xs text-slate-500">Showing <span className="font-bold text-white">1</span> to <span className="font-bold text-white">5</span> of 42 results</span>
          <div className="flex items-center gap-1">
            <button className="p-2 text-slate-500 hover:text-white bg-slate-800 rounded disabled:opacity-50" disabled>Prev</button>
            <button className="w-8 h-8 flex items-center justify-center rounded bg-[#2b2bee] text-white text-xs font-bold">1</button>
            <button className="w-8 h-8 flex items-center justify-center rounded hover:bg-slate-800 text-slate-400 text-xs font-bold">2</button>
            <button className="w-8 h-8 flex items-center justify-center rounded hover:bg-slate-800 text-slate-400 text-xs font-bold">3</button>
            <span className="px-2 text-slate-600">...</span>
            <button className="w-8 h-8 flex items-center justify-center rounded hover:bg-slate-800 text-slate-400 text-xs font-bold">8</button>
            <button className="p-2 text-slate-500 hover:text-white bg-slate-800 rounded">Next</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ClubMembers;
