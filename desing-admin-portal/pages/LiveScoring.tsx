
import React from 'react';
import { 
  Trophy, 
  Search, 
  Filter, 
  Star, 
  Activity, 
  TrendingUp, 
  Medal,
  Flag,
  RotateCw
} from 'lucide-react';

const LiveScoring = () => {
  const standings = [
    { rank: 1, club: 'Orion Pathfinders', field: 'Greater NY', total: 985, status: 'Completed', trend: 'up' },
    { rank: 2, club: 'Alpha Centauri', field: 'Northeastern', total: 972, status: 'Completed', trend: 'up' },
    { rank: 3, club: 'Pleiades Club', field: 'SNEC', total: 968, status: 'In Review', trend: 'down' },
    { rank: 4, club: 'Northern Stars', field: 'NY Conf', total: 940, status: 'Completed', trend: 'up' },
    { rank: 5, club: 'Eagle Watchers', field: 'Atlantic Union', total: 935, status: 'Completed', trend: 'down' },
  ];

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-6">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <h1 className="text-3xl font-black text-white uppercase tracking-tighter">Live Scoring Center</h1>
            <div className="flex items-center gap-2 px-3 py-1 bg-red-500/10 rounded-full border border-red-500/20">
              <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
              <span className="text-[10px] font-black text-red-500 uppercase tracking-widest">Live Updates</span>
            </div>
          </div>
          <p className="text-slate-500 text-sm font-medium">Monitoring competition results across all union categories.</p>
        </div>
        <div className="flex gap-3">
          <button className="p-2 bg-slate-900 border border-slate-800 rounded-lg text-slate-400 hover:text-white transition-colors">
            <RotateCw size={20} />
          </button>
          <button className="bg-[#2b2bee] hover:bg-[#1e1ebd] text-white px-6 py-2 rounded-lg font-bold text-sm shadow-lg shadow-[#2b2bee]/20 transition-all flex items-center gap-2">
            <Star size={18} />
            Add New Score
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { label: 'Top Field', value: 'Greater NY', sub: 'Field Average: 954', icon: <Medal /> },
          { label: 'Total Events', value: '18 / 24', sub: '75% Progress', icon: <Activity /> },
          { label: 'Highest Score', value: '985 pts', sub: 'Club: Orion', icon: <Trophy /> },
          { label: 'Clubs Present', value: '342', sub: '98% Attendance', icon: <Flag /> },
        ].map((stat, i) => (
          <div key={i} className="bg-[#16162c] border border-slate-800 p-6 rounded-xl hover:border-slate-700 transition-all">
            <div className="text-[#2b2bee] mb-4">{stat.icon}</div>
            <div className="text-[10px] font-bold text-slate-500 uppercase tracking-widest mb-1">{stat.label}</div>
            <div className="text-xl font-black text-white mb-1">{stat.value}</div>
            <div className="text-xs text-slate-400 font-medium">{stat.sub}</div>
          </div>
        ))}
      </div>

      {/* Competition Tabs */}
      <div className="flex items-center gap-8 border-b border-slate-800">
         {['Bible Bowl', 'Drill & Marching', 'Inspections', 'Uniform', 'Campsite'].map((cat, i) => (
           <button key={i} className={`pb-4 text-sm font-bold transition-all relative ${i === 1 ? 'text-[#2b2bee]' : 'text-slate-500 hover:text-slate-300'}`}>
              {cat}
              {i === 1 && <div className="absolute bottom-0 left-0 right-0 h-1 bg-[#2b2bee] rounded-t-full"></div>}
           </button>
         ))}
      </div>

      <div className="bg-[#16162c] border border-slate-800 rounded-2xl overflow-hidden shadow-2xl">
        <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-900/30">
           <h2 className="text-lg font-bold text-white uppercase tracking-tight">Leaderboard: <span className="text-[#2b2bee]">Drill & Marching</span></h2>
           <div className="relative">
              <Search className="absolute left-3 top-2 text-slate-500" size={16} />
              <input className="pl-10 pr-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-xs text-white w-64" placeholder="Find club..." />
           </div>
        </div>
        <table className="w-full text-left">
          <thead>
            <tr className="bg-slate-950/50 text-[10px] uppercase font-black tracking-widest text-slate-600 border-b border-slate-800">
              <th className="px-8 py-4 w-20">Rank</th>
              <th className="px-8 py-4">Club Entity</th>
              <th className="px-8 py-4">Geographical Field</th>
              <th className="px-8 py-4">Status</th>
              <th className="px-8 py-4 text-right">Points</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/50">
            {standings.map((row, i) => (
              <tr key={i} className={`group hover:bg-[#2b2bee]/5 transition-all ${i < 3 ? 'bg-[#2b2bee]/2' : ''}`}>
                <td className="px-8 py-6">
                   <div className={`w-8 h-8 rounded-full flex items-center justify-center font-black ${
                     i === 0 ? 'bg-amber-400 text-amber-950 shadow-[0_0_15px_rgba(251,191,36,0.4)]' : 
                     i === 1 ? 'bg-slate-300 text-slate-900' : 
                     i === 2 ? 'bg-amber-700 text-amber-100' : 
                     'text-slate-500 border border-slate-800'
                   }`}>
                     {row.rank}
                   </div>
                </td>
                <td className="px-8 py-6">
                   <div className="text-white font-bold text-sm group-hover:text-[#2b2bee] transition-colors">{row.club}</div>
                   <div className="text-[10px] text-slate-500 font-medium">Unit Type: Senior Pathfinder</div>
                </td>
                <td className="px-8 py-6 text-sm text-slate-400 font-medium">{row.field}</td>
                <td className="px-8 py-6">
                   <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                     row.status === 'Completed' ? 'bg-green-500/10 text-green-500' : 'bg-amber-500/10 text-amber-500'
                   }`}>{row.status}</span>
                </td>
                <td className="px-8 py-6 text-right">
                   <div className="flex items-center justify-end gap-3">
                      {row.trend === 'up' ? <TrendingUp size={14} className="text-green-500" /> : <Star size={14} className="text-amber-500" />}
                      <span className="text-xl font-black text-white font-mono">{row.total}</span>
                   </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="p-6 bg-slate-950/30 text-center">
           <button className="text-xs font-bold text-slate-500 hover:text-white uppercase tracking-widest">Export Full Leaderboard (PDF)</button>
        </div>
      </div>
    </div>
  );
};

export default LiveScoring;
