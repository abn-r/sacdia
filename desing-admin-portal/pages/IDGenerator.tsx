
import React from 'react';
import { 
  Printer, 
  FileDown, 
  QrCode, 
  Wifi, 
  CheckCircle, 
  AlertCircle,
  Clock,
  MapPin,
  MoreVertical
} from 'lucide-react';

const IDGenerator = () => {
  const liveFeed = [
    { name: 'Maria Rodriguez', club: 'Orion Pathfinders', time: 'Just now', location: 'Main Cafeteria', status: 'Granted', avatar: 'https://picsum.photos/seed/maria/40/40' },
    { name: 'David Smith', club: 'Alpha Centauri', time: '14:04:12', location: 'Main Cafeteria', status: 'Granted', avatar: 'https://picsum.photos/seed/dsmith/40/40' },
    { name: 'Unknown / Invalid', club: 'QR Code Unreadable', time: '14:02:55', location: 'North Gate', status: 'Denied', icon: <AlertCircle className="text-red-500" /> },
    { name: 'Sarah Jones', club: 'Pleiades Club', time: '14:01:20', location: 'Auditorium', status: 'Granted', avatar: 'https://picsum.photos/seed/sjones/40/40' },
  ];

  return (
    <div className="h-full flex flex-col gap-8 animate-in fade-in duration-500">
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 h-full">
        {/* Left Side: Generator */}
        <div className="lg:col-span-7 flex flex-col gap-6">
          <div className="bg-[#16162c] border border-slate-800 rounded-xl p-6 shadow-sm">
             <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
                <div>
                   <h1 className="text-2xl font-bold text-white mb-1">Credential Generator</h1>
                   <p className="text-sm text-slate-500">Generate and print standardized ID cards for club members.</p>
                </div>
                <div className="flex gap-2">
                   <button className="flex items-center gap-2 px-3 py-2 bg-slate-900 border border-slate-800 rounded-lg text-xs font-bold text-slate-300 hover:text-white transition-all"><Printer size={16} /> Print</button>
                   <button className="flex items-center gap-2 px-3 py-2 bg-slate-900 border border-slate-800 rounded-lg text-xs font-bold text-slate-300 hover:text-white transition-all"><FileDown size={16} /> PDF</button>
                </div>
             </div>

             <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
               <div className="space-y-1.5">
                 <label className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Federation</label>
                 <select className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-white">
                   <option>North Conference</option>
                 </select>
               </div>
               <div className="space-y-1.5">
                 <label className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Club Type</label>
                 <select className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-white">
                   <option>Pathfinder Club</option>
                 </select>
               </div>
               <div className="space-y-1.5">
                 <label className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Specific Club</label>
                 <select className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-white">
                   <option>Orion Pathfinder Club</option>
                 </select>
               </div>
             </div>

             <div className="flex justify-between items-center pt-6 border-t border-slate-800">
               <span className="text-sm text-slate-500">Selected: <span className="font-bold text-white">42 Members</span></span>
               <button className="bg-[#2b2bee] hover:bg-[#1e1ebd] text-white px-6 py-2.5 rounded-lg text-sm font-bold shadow-lg shadow-[#2b2bee]/20 transition-all flex items-center gap-2">
                 <Wifi size={18} />
                 Generate Batch
               </button>
             </div>
          </div>

          <div className="flex-1 bg-black/20 rounded-xl border border-slate-800/50 p-8 flex items-center justify-center relative overflow-hidden group">
             {/* THE ID CARD */}
             <div className="w-[320px] h-[500px] bg-[#16162c] rounded-2xl shadow-2xl overflow-hidden border border-slate-700 flex flex-col relative animate-in zoom-in-95 duration-500">
                <div className="absolute top-4 left-1/2 -translate-x-1/2 w-12 h-1.5 bg-slate-800 rounded-full"></div>
                
                <div className="h-24 bg-gradient-to-r from-blue-900 to-[#2b2bee] flex flex-col items-center justify-center p-4">
                  <h3 className="text-white font-black text-lg tracking-widest uppercase">Pathfinders</h3>
                  <p className="text-blue-100 text-[8px] uppercase tracking-widest font-bold opacity-70">Seventh-day Adventist Church</p>
                </div>

                <div className="flex flex-col items-center -mt-10 mb-2">
                   <div className="p-1 bg-[#16162c] rounded-full">
                     <img src="https://picsum.photos/seed/id/200/200" className="w-24 h-24 rounded-full border-4 border-[#16162c] object-cover shadow-xl" alt="Member" />
                   </div>
                   <h2 className="text-2xl font-black text-white mt-4">Juan Perez</h2>
                   <span className="inline-block px-3 py-1 bg-[#2b2bee]/10 text-[#2b2bee] rounded-full text-[10px] font-black uppercase tracking-widest mt-2 border border-[#2b2bee]/20">
                     Club Director
                   </span>
                </div>

                <div className="px-8 mt-6">
                  <div className="grid grid-cols-2 gap-y-4 text-left border-t border-b border-slate-800 py-6">
                    <div>
                      <p className="text-slate-500 uppercase text-[8px] font-bold tracking-widest">Club</p>
                      <p className="font-bold text-slate-200 text-sm">Orion</p>
                    </div>
                    <div>
                      <p className="text-slate-500 uppercase text-[8px] font-bold tracking-widest">Blood Type</p>
                      <p className="font-bold text-slate-200 text-sm">O+</p>
                    </div>
                    <div>
                      <p className="text-slate-500 uppercase text-[8px] font-bold tracking-widest">Valid Thru</p>
                      <p className="font-bold text-slate-200 text-sm">Dec 2024</p>
                    </div>
                    <div>
                      <p className="text-slate-500 uppercase text-[8px] font-bold tracking-widest">ID</p>
                      <p className="font-bold text-slate-200 text-sm font-mono">#982-11A</p>
                    </div>
                  </div>
                </div>

                <div className="mt-auto p-8 flex flex-col items-center">
                   <div className="bg-white p-2 rounded-lg relative overflow-hidden group">
                      <QrCode size={80} className="text-slate-900" />
                      <div className="absolute inset-0 bg-[#2b2bee]/20 animate-pulse"></div>
                   </div>
                   <p className="text-[8px] font-bold text-slate-600 mt-4 uppercase tracking-widest">Scan for Access Verification</p>
                </div>
                <div className="h-2 bg-amber-500 w-full shrink-0"></div>
             </div>
          </div>
        </div>

        {/* Right Side: Access Monitor */}
        <div className="lg:col-span-5 flex flex-col bg-[#16162c] border border-slate-800 rounded-xl overflow-hidden shadow-xl">
           <div className="p-4 border-b border-slate-800 bg-slate-900/50 flex justify-between items-center">
              <div className="flex items-center gap-3">
                 <div className="w-2 h-2 rounded-full bg-red-500 animate-ping"></div>
                 <h2 className="font-black text-white uppercase tracking-widest text-xs">Live Access Feed</h2>
              </div>
              <div className="text-[10px] font-mono text-slate-500">08:43:20 UTC</div>
           </div>

           <div className="grid grid-cols-3 divide-x divide-slate-800 border-b border-slate-800">
             <div className="p-4 text-center">
               <div className="text-2xl font-bold text-white font-mono">1,240</div>
               <div className="text-[8px] uppercase font-black text-slate-500 tracking-tighter">Total Scans</div>
             </div>
             <div className="p-4 text-center">
               <div className="text-2xl font-bold text-[#2b2bee] font-mono">856</div>
               <div className="text-[8px] uppercase font-black text-slate-500 tracking-tighter">On Site</div>
             </div>
             <div className="p-4 text-center">
               <div className="text-2xl font-bold text-amber-500 font-mono">384</div>
               <div className="text-[8px] uppercase font-black text-slate-500 tracking-tighter">Pending</div>
             </div>
           </div>

           <div className="flex-1 overflow-y-auto custom-scrollbar p-4 space-y-3">
             {liveFeed.map((entry, idx) => (
               <div key={idx} className={`p-4 rounded-lg flex items-center gap-4 border transition-all ${
                 idx === 0 
                   ? 'bg-green-500/5 border-green-500/20' 
                   : entry.status === 'Denied' 
                     ? 'bg-red-500/5 border-red-500/20' 
                     : 'bg-slate-900 border-slate-800'
               }`}>
                 <div className="shrink-0">
                    {entry.avatar ? (
                      <img src={entry.avatar} className={`w-10 h-10 rounded-full border border-slate-800 ${idx !== 0 && 'grayscale opacity-60'}`} alt="avatar" />
                    ) : (
                      <div className="w-10 h-10 rounded-full bg-red-500/10 flex items-center justify-center">
                        {entry.icon}
                      </div>
                    )}
                 </div>
                 <div className="flex-1 min-w-0">
                   <div className="flex justify-between items-start">
                     <h4 className={`text-sm font-bold truncate ${entry.status === 'Denied' ? 'text-red-400' : 'text-slate-200'}`}>{entry.name}</h4>
                     <span className="text-[10px] font-mono text-slate-500 shrink-0">{entry.time}</span>
                   </div>
                   <p className="text-[10px] text-slate-500 truncate">{entry.club}</p>
                   <div className="flex items-center gap-1.5 mt-1 text-[10px] text-slate-600">
                     <MapPin size={10} />
                     <span>{entry.location}</span>
                   </div>
                 </div>
                 <div className={`px-2 py-0.5 rounded text-[8px] font-black uppercase border ${
                   entry.status === 'Granted' ? 'bg-green-500/10 text-green-500 border-green-500/20' : 'bg-red-500/10 text-red-500 border-red-500/20'
                 }`}>
                   {entry.status}
                 </div>
               </div>
             ))}
           </div>

           <div className="p-4 border-t border-slate-800 bg-slate-900/50">
             <button className="w-full py-2 bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white rounded-lg text-xs font-bold transition-all flex items-center justify-center gap-2">
               Manual Entry Log
             </button>
           </div>
        </div>
      </div>
    </div>
  );
};

export default IDGenerator;
