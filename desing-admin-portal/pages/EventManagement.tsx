
import React from 'react';
import { 
  Tent, 
  Calendar, 
  Users, 
  Map as MapIcon, 
  ChefHat, 
  Truck, 
  Plus, 
  ChevronRight,
  TrendingUp,
  Info
} from 'lucide-react';

const EventManagement = () => {
  const events = [
    { title: 'I Camporee Unión Atlántica', date: 'Jul 15-20, 2024', status: 'Active', registered: 4500, target: 5000, theme: 'Chosen by God' },
    { title: 'Bible Bowl Finals', date: 'May 10, 2024', status: 'Upcoming', registered: 200, target: 200, theme: 'Exodus' },
    { title: 'Youth Leadership Summit', date: 'Sep 05, 2024', status: 'Draft', registered: 0, target: 100, theme: 'Servant Hearts' },
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">Events & Camporees</h1>
          <p className="text-slate-500 text-sm">Coordinate logistics, registrations and resources for union-wide events.</p>
        </div>
        <button className="bg-[#2b2bee] hover:bg-[#1e1ebd] text-white px-6 py-2.5 rounded-xl font-bold flex items-center gap-2 transition-all">
          <Plus size={20} />
          Create Event
        </button>
      </div>

      {/* Main Event Hero */}
      <div className="bg-[#16162c] border border-slate-800 rounded-2xl p-8 relative overflow-hidden group">
        <div className="absolute top-0 right-0 p-32 bg-indigo-500/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>
        <div className="relative z-10 flex flex-col lg:flex-row gap-12">
          <div className="flex-1 space-y-6">
            <div className="flex items-center gap-3">
               <span className="px-3 py-1 bg-green-500/10 text-green-500 text-[10px] font-black uppercase tracking-widest rounded-full border border-green-500/20">Next Major Event</span>
               <span className="text-slate-500 font-mono text-xs">ID: EV-2024-001</span>
            </div>
            <h2 className="text-4xl font-black text-white leading-tight">V Camporee Union <br/><span className="text-[#2b2bee]">"CONQUISTADORES"</span></h2>
            <div className="flex flex-wrap gap-6 text-slate-300">
               <div className="flex items-center gap-2">
                 <Calendar className="text-[#2b2bee]" size={20} />
                 <span className="font-bold">August 12 - 17, 2024</span>
               </div>
               <div className="flex items-center gap-2">
                 <MapIcon className="text-[#2b2bee]" size={20} />
                 <span className="font-bold">Victory Ranch, NJ</span>
               </div>
            </div>
            <div className="space-y-2">
               <div className="flex justify-between text-sm font-bold">
                 <span className="text-slate-400">Registration Progress</span>
                 <span className="text-white">82% (4,100 / 5,000)</span>
               </div>
               <div className="w-full bg-slate-900 h-3 rounded-full overflow-hidden border border-slate-800">
                 <div className="h-full bg-gradient-to-r from-[#2b2bee] to-indigo-400 rounded-full" style={{width: '82%'}}></div>
               </div>
            </div>
          </div>
          <div className="w-full lg:w-80 grid grid-cols-2 gap-4">
             {[
               { icon: <ChefHat />, label: 'Food Plans', value: '15.4k Servings' },
               { icon: <Tent />, label: 'Campsites', value: '342 Reserved' },
               { icon: <Truck />, label: 'Logistics', value: '12 Shipments' },
               { icon: <Users />, label: 'Staff', value: '120 Assigned' }
             ].map((item, i) => (
               <div key={i} className="bg-slate-900/50 border border-slate-800 p-4 rounded-xl flex flex-col gap-2 hover:border-slate-700 transition-colors">
                  <div className="text-[#2b2bee]">{item.icon}</div>
                  <div className="text-[10px] font-bold text-slate-500 uppercase">{item.label}</div>
                  <div className="text-sm font-bold text-white">{item.value}</div>
               </div>
             ))}
          </div>
        </div>
      </div>

      {/* Event List */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {events.map((ev, i) => (
          <div key={i} className="bg-[#16162c] border border-slate-800 rounded-xl p-6 hover:shadow-xl hover:translate-y-[-4px] transition-all cursor-pointer">
            <div className="flex justify-between items-start mb-6">
              <div className="w-12 h-12 bg-slate-900 rounded-xl flex items-center justify-center text-slate-400">
                <Tent size={24} />
              </div>
              <span className={`px-2 py-1 rounded text-[10px] font-black uppercase tracking-widest ${
                ev.status === 'Active' ? 'bg-green-500/10 text-green-500 border border-green-500/20' : 
                ev.status === 'Draft' ? 'bg-slate-500/10 text-slate-500 border border-slate-500/20' : 
                'bg-amber-500/10 text-amber-500 border border-amber-500/20'
              }`}>{ev.status}</span>
            </div>
            <h3 className="text-lg font-bold text-white mb-1">{ev.title}</h3>
            <p className="text-xs text-slate-500 mb-6 italic">Theme: "{ev.theme}"</p>
            
            <div className="space-y-4">
               <div className="flex items-center gap-3 text-xs text-slate-400">
                  <Calendar size={14} /> {ev.date}
               </div>
               <div className="flex items-center gap-3 text-xs text-slate-400">
                  <Users size={14} /> {ev.registered} / {ev.target} Members
               </div>
               <div className="pt-4 border-t border-slate-800 flex justify-between items-center">
                  <span className="text-[10px] font-bold text-slate-600 uppercase">View Details</span>
                  <ChevronRight size={16} className="text-slate-600" />
               </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default EventManagement;
