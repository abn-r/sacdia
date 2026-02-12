
import React from 'react';
import { 
  Users, 
  Home, 
  Award, 
  Clock, 
  TrendingUp,
  MoreVertical
} from 'lucide-react';
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  AreaChart,
  Area
} from 'recharts';

const data = [
  { name: 'Week 1', users: 400 },
  { name: 'Week 2', users: 800 },
  { name: 'Week 3', users: 1200 },
  { name: 'Week 4', users: 1100 },
  { name: 'Week 5', users: 1800 },
];

const StatCard = ({ label, value, trend, icon, color }: { label: string, value: string, trend: string, icon: React.ReactNode, color: string }) => (
  <div className="bg-[#16162c] border border-slate-800 rounded-xl p-6 relative overflow-hidden group">
    <div className={`absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity ${color}`}>
      {icon}
    </div>
    <div className="flex flex-col">
      <span className="text-slate-400 text-sm font-medium mb-1">{label}</span>
      <div className="flex items-baseline gap-2">
        <span className="text-2xl font-bold text-white">{value}</span>
        <span className="text-xs font-semibold text-green-500 flex items-center">
          <TrendingUp size={12} className="mr-0.5" />
          {trend}
        </span>
      </div>
    </div>
  </div>
);

const Dashboard = () => {
  const recentRegistrations = [
    { name: 'James Wilson', role: 'Club Director', club: 'Pathfinders', date: 'Oct 24, 2023', status: 'Approved', avatar: 'https://picsum.photos/seed/1/32/32' },
    { name: 'Sarah Chen', role: 'Counselor', club: 'Adventurers', date: 'Oct 23, 2023', status: 'Pending', avatar: 'https://picsum.photos/seed/2/32/32' },
    { name: 'Michael Rodriguez', role: 'Instructor', club: 'Master Guides', date: 'Oct 22, 2023', status: 'Approved', avatar: 'https://picsum.photos/seed/3/32/32' },
    { name: 'Emily Davis', role: 'Secretary', club: 'Pathfinders', date: 'Oct 21, 2023', status: 'Pending', avatar: 'https://picsum.photos/seed/4/32/32' },
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div>
        <h1 className="text-2xl font-bold text-white mb-1">Dashboard Overview</h1>
        <p className="text-slate-500 text-sm">Welcome back. Here's what's happening with your clubs today.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard 
          label="Total Users" 
          value="12,450" 
          trend="12%" 
          icon={<Users size={48} />} 
          color="text-blue-500" 
        />
        <StatCard 
          label="Active Clubs" 
          value="342" 
          trend="2%" 
          icon={<Home size={48} />} 
          color="text-purple-500" 
        />
        <StatCard 
          label="Invested Members" 
          value="8,100" 
          trend="8%" 
          icon={<Award size={48} />} 
          color="text-blue-400" 
        />
        <StatCard 
          label="Pending Approvals" 
          value="15" 
          trend="Needs Action" 
          icon={<Clock size={48} />} 
          color="text-amber-500" 
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-[#16162c] border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between mb-8">
            <h2 className="text-lg font-bold text-white">New User Registrations</h2>
            <select className="bg-slate-900 border border-slate-800 text-xs rounded px-2 py-1 text-slate-400 focus:outline-none">
              <option>Last 30 Days</option>
              <option>Last 6 Months</option>
            </select>
          </div>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data}>
                <defs>
                  <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2b2bee" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#2b2bee" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#232342" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#4b5563', fontSize: 12}} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: '#4b5563', fontSize: 12}} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#16162c', border: '1px solid #232342', borderRadius: '8px' }}
                  itemStyle={{ color: '#fff' }}
                />
                <Area type="monotone" dataKey="users" stroke="#2b2bee" strokeWidth={3} fillOpacity={1} fill="url(#colorUsers)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-[#16162c] border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-bold text-white mb-6">Members by Club Type</h2>
          <div className="space-y-6">
             <div className="flex flex-col gap-2">
               <div className="flex justify-between text-sm">
                 <span className="text-slate-400">Pathfinders</span>
                 <span className="text-white font-bold">5,240</span>
               </div>
               <div className="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                 <div className="bg-[#2b2bee] h-full rounded-full" style={{width: '65%'}}></div>
               </div>
             </div>
             <div className="flex flex-col gap-2">
               <div className="flex justify-between text-sm">
                 <span className="text-slate-400">Adventurers</span>
                 <span className="text-white font-bold">4,120</span>
               </div>
               <div className="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                 <div className="bg-purple-500 h-full rounded-full" style={{width: '45%'}}></div>
               </div>
             </div>
             <div className="flex flex-col gap-2">
               <div className="flex justify-between text-sm">
                 <span className="text-slate-400">Master Guides</span>
                 <span className="text-white font-bold">3,090</span>
               </div>
               <div className="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                 <div className="bg-blue-400 h-full rounded-full" style={{width: '35%'}}></div>
               </div>
             </div>
          </div>
        </div>
      </div>

      <div className="bg-[#16162c] border border-slate-800 rounded-xl overflow-hidden">
        <div className="p-6 border-b border-slate-800 flex justify-between items-center">
          <h2 className="text-lg font-bold text-white">Recent Registrations</h2>
          <button className="text-sm font-medium text-[#2b2bee] hover:underline">View All</button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="text-slate-500 text-xs uppercase tracking-wider border-b border-slate-800">
                <th className="px-6 py-4 font-semibold">User</th>
                <th className="px-6 py-4 font-semibold">Role</th>
                <th className="px-6 py-4 font-semibold">Club</th>
                <th className="px-6 py-4 font-semibold">Date</th>
                <th className="px-6 py-4 font-semibold text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {recentRegistrations.map((reg, idx) => (
                <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <img src={reg.avatar} alt={reg.name} className="w-8 h-8 rounded-full" />
                      <div className="text-sm">
                        <div className="font-bold text-slate-100">{reg.name}</div>
                        <div className="text-slate-500 text-[10px]">user@example.com</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-400">{reg.role}</td>
                  <td className="px-6 py-4 text-sm">
                    <span className="bg-[#2b2bee]/10 text-[#2b2bee] px-2 py-0.5 rounded text-xs">
                      {reg.club}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-500">{reg.date}</td>
                  <td className="px-6 py-4 text-right">
                    <span className={`px-2 py-1 rounded text-[10px] font-bold uppercase ${
                      reg.status === 'Approved' ? 'bg-green-500/10 text-green-500' : 'bg-amber-500/10 text-amber-500'
                    }`}>
                      {reg.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
