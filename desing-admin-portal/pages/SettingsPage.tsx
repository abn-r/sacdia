
import React from 'react';
import { 
  Shield, 
  Bell, 
  User, 
  Database, 
  Globe, 
  Mail, 
  ChevronRight,
  LogOut,
  Lock,
  Smartphone
} from 'lucide-react';

const SettingsPage = () => {
  const sections = [
    { icon: <User size={20} />, title: 'Account Profile', sub: 'Manage your administrative details' },
    { icon: <Shield size={20} />, title: 'Security & Auth', sub: 'Password, 2FA and login sessions' },
    { icon: <Bell size={20} />, title: 'Notifications', sub: 'Email and system alert preferences' },
    { icon: <Database size={20} />, title: 'Data Management', sub: 'Export records and backup system' },
    { icon: <Globe size={20} />, title: 'API & Integrations', sub: 'Webhooks and third-party tools' },
  ];

  return (
    <div className="h-full flex flex-col gap-8 animate-in fade-in duration-500">
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
        {/* Navigation Sidebar */}
        <div className="lg:col-span-4 space-y-2">
          <h1 className="text-2xl font-bold text-white mb-6">Settings</h1>
          {sections.map((s, i) => (
            <button key={i} className={`w-full flex items-center gap-4 p-4 rounded-xl transition-all text-left ${
              i === 0 ? 'bg-[#2b2bee]/10 border border-[#2b2bee]/20 text-white' : 'text-slate-500 hover:bg-slate-800/50 hover:text-slate-300'
            }`}>
              <div className={`${i === 0 ? 'text-[#2b2bee]' : 'text-slate-600'}`}>{s.icon}</div>
              <div>
                <div className="text-sm font-bold">{s.title}</div>
                <div className="text-[10px] font-medium opacity-60">{s.sub}</div>
              </div>
            </button>
          ))}
          <div className="pt-8">
            <button className="w-full flex items-center gap-3 p-4 text-red-500 hover:bg-red-500/5 rounded-xl text-sm font-bold transition-all">
              <LogOut size={20} />
              Terminate All Sessions
            </button>
          </div>
        </div>

        {/* Settings Content Area */}
        <div className="lg:col-span-8 bg-[#16162c] border border-slate-800 rounded-2xl overflow-hidden">
           <div className="p-8 border-b border-slate-800">
             <h2 className="text-xl font-bold text-white mb-2">Account Profile</h2>
             <p className="text-sm text-slate-500">Update your account information and how others see you on the platform.</p>
           </div>
           
           <div className="p-8 space-y-10">
              <div className="flex flex-col md:flex-row gap-8 items-start">
                <div className="relative group">
                   <img src="https://picsum.photos/id/64/100/100" className="w-24 h-24 rounded-2xl border-2 border-slate-700 object-cover" alt="Profile" />
                   <div className="absolute inset-0 bg-black/60 rounded-2xl opacity-0 group-hover:opacity-100 flex items-center justify-center cursor-pointer transition-opacity">
                      <span className="text-[10px] font-bold text-white uppercase">Change</span>
                   </div>
                </div>
                <div className="flex-1 grid grid-cols-1 md:grid-cols-2 gap-6 w-full">
                   <div className="space-y-1.5">
                     <label className="text-xs font-bold text-slate-500 uppercase tracking-widest">Full Name</label>
                     <input className="w-full bg-slate-900 border border-slate-800 rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:ring-1 focus:ring-[#2b2bee]" defaultValue="Admin User" />
                   </div>
                   <div className="space-y-1.5">
                     <label className="text-xs font-bold text-slate-500 uppercase tracking-widest">Email Address</label>
                     <input className="w-full bg-slate-900 border border-slate-800 rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:ring-1 focus:ring-[#2b2bee]" defaultValue="admin@sacdia.org" />
                   </div>
                   <div className="space-y-1.5">
                     <label className="text-xs font-bold text-slate-500 uppercase tracking-widest">System Language</label>
                     <select className="w-full bg-slate-900 border border-slate-800 rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:ring-1 focus:ring-[#2b2bee]">
                        <option>English (US)</option>
                        <option>Español (Latinoamérica)</option>
                        <option>Français</option>
                     </select>
                   </div>
                </div>
              </div>

              <div className="space-y-6">
                <h3 className="text-sm font-bold text-white uppercase tracking-tighter">Security Preferences</h3>
                <div className="space-y-4">
                  {[
                    { icon: <Lock />, title: 'Two-Factor Authentication', sub: 'Adds an extra layer of security to your account', active: true },
                    { icon: <Smartphone />, title: 'Mobile Verification', sub: 'Receive SMS codes for critical account actions', active: false },
                    { icon: <Mail />, title: 'Login Alerts', sub: 'Get notified of new login attempts from unknown devices', active: true },
                  ].map((item, i) => (
                    <div key={i} className="flex items-center justify-between p-4 bg-slate-900/50 rounded-xl border border-slate-800">
                       <div className="flex items-center gap-4">
                          <div className="p-2 bg-slate-950 rounded-lg text-slate-500">{item.icon}</div>
                          <div>
                            <div className="text-sm font-bold text-slate-200">{item.title}</div>
                            <div className="text-[10px] text-slate-500 font-medium">{item.sub}</div>
                          </div>
                       </div>
                       <div className={`w-10 h-5 rounded-full relative cursor-pointer transition-colors ${item.active ? 'bg-[#2b2bee]' : 'bg-slate-700'}`}>
                          <div className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-all ${item.active ? 'right-0.5' : 'left-0.5'}`}></div>
                       </div>
                    </div>
                  ))}
                </div>
              </div>
           </div>

           <div className="p-8 bg-slate-900/50 border-t border-slate-800 flex justify-end gap-3">
              <button className="px-6 py-2.5 rounded-xl border border-slate-700 text-sm font-bold text-slate-400 hover:text-white transition-all">Discard</button>
              <button className="px-8 py-2.5 rounded-xl bg-[#2b2bee] hover:bg-[#1e1ebd] text-white text-sm font-bold shadow-lg shadow-[#2b2bee]/20 transition-all">Save Profile</button>
           </div>
        </div>
      </div>
    </div>
  );
};

export default SettingsPage;
