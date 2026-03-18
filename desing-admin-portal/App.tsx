
import React from 'react';
import { HashRouter, Routes, Route, Link, useLocation } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Users, 
  Map, 
  Settings, 
  ClipboardCheck, 
  Medal,
  LogOut,
  Bell,
  Search,
  ChevronRight,
  UserPlus,
  Trophy,
  Tent,
  ShieldCheck,
  Key,
  BookOpen
} from 'lucide-react';

// Pages
import Dashboard from './pages/Dashboard';
import MemberApprovals from './pages/MemberApprovals';
import GeographicalHierarchy from './pages/GeographicalHierarchy';
import ClubMembers from './pages/ClubMembers';
import CurriculumManagement from './pages/CurriculumManagement';
import IDGenerator from './pages/IDGenerator';
import EventManagement from './pages/EventManagement';
import LiveScoring from './pages/LiveScoring';
import SettingsPage from './pages/SettingsPage';
import RolesPermissions from './pages/RolesPermissions';
import RolesCatalog from './pages/RolesCatalog';
import PermissionsCatalog from './pages/PermissionsCatalog';

const Sidebar = () => {
  const location = useLocation();
  const menuItems = [
    { label: 'Dashboard', path: '/', icon: <LayoutDashboard size={20} /> },
    { label: 'Approvals', path: '/approvals', icon: <UserPlus size={20} />, badge: 12 },
    { label: 'Members', path: '/members', icon: <Users size={20} /> },
    { label: 'Geographical', path: '/geographical', icon: <Map size={20} /> },
    { label: 'Events & Camporee', path: '/events', icon: <Tent size={20} /> },
    { label: 'Curriculum', path: '/curriculum', icon: <ClipboardCheck size={20} /> },
    { label: 'Live Scoring', path: '/scoring', icon: <Trophy size={20} /> },
    { 
      label: 'Security Matrix', 
      path: '/roles-matrix', 
      icon: <ShieldCheck size={20} />,
      children: [
        { label: 'Assignment Matrix', path: '/roles-matrix', icon: <ShieldCheck size={16} /> },
        { label: 'Roles Catalog', path: '/catalog/roles', icon: <Key size={16} /> },
        { label: 'Permissions Catalog', path: '/catalog/permissions', icon: <BookOpen size={16} /> },
      ]
    },
    { label: 'Credentials', path: '/credentials', icon: <Medal size={20} /> },
    { label: 'Settings', path: '/settings', icon: <Settings size={20} /> },
  ];

  return (
    <aside className="w-64 flex flex-col h-screen border-r border-slate-800 bg-[#101022] z-20 shrink-0">
      <div className="h-16 flex items-center px-6 border-b border-slate-800">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-[#2b2bee] flex items-center justify-center text-white font-bold">S</div>
          <span className="font-bold text-lg tracking-tight text-white">SACDIA</span>
        </div>
      </div>
      <nav className="flex-1 px-3 py-6 space-y-1 overflow-y-auto custom-scrollbar">
        {menuItems.map((item) => (
          <div key={item.path}>
            <Link
              to={item.path}
              className={`flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                location.pathname === item.path || (item.children && item.children.some(c => location.pathname === c.path))
                  ? 'bg-[#2b2bee]/10 text-white' 
                  : 'text-slate-400 hover:bg-slate-800 hover:text-white'
              }`}
            >
              {item.icon}
              <span className="flex-1">{item.label}</span>
              {item.badge && (
                <span className="bg-[#2b2bee] text-white text-[10px] px-2 py-0.5 rounded-full">
                  {item.badge}
                </span>
              )}
            </Link>
            {item.children && (location.pathname.startsWith('/roles-matrix') || location.pathname.startsWith('/catalog')) && (
              <div className="ml-6 mt-1 space-y-1">
                {item.children.map(child => (
                  <Link
                    key={child.path}
                    to={child.path}
                    className={`flex items-center gap-3 px-4 py-2 text-xs font-medium rounded-lg transition-colors ${
                      location.pathname === child.path 
                        ? 'text-[#2b2bee]' 
                        : 'text-slate-500 hover:text-slate-300'
                    }`}
                  >
                    {child.icon}
                    {child.label}
                  </Link>
                ))}
              </div>
            )}
          </div>
        ))}
      </nav>
      <div className="p-4 border-t border-slate-800">
        <div className="flex items-center gap-3 px-2 py-2 mb-4">
          <img 
            src="https://picsum.photos/id/64/40/40" 
            className="w-10 h-10 rounded-full border border-slate-700" 
            alt="Admin" 
          />
          <div className="text-sm overflow-hidden">
            <div className="font-medium text-white truncate">Admin User</div>
            <div className="text-xs text-slate-500 truncate">admin@sacdia.org</div>
          </div>
        </div>
        <button className="w-full flex items-center gap-3 px-4 py-2 text-sm font-medium text-slate-400 hover:text-red-400 hover:bg-red-400/5 rounded-lg transition-colors">
          <LogOut size={18} />
          Sign Out
        </button>
      </div>
    </aside>
  );
};

const Header = () => {
  const location = useLocation();
  const pathParts = location.pathname.split('/').filter(p => p);
  
  return (
    <header className="h-16 flex items-center justify-between px-8 border-b border-slate-800 bg-[#101022]/80 backdrop-blur-sm sticky top-0 z-10">
      <div className="flex items-center gap-4">
        <nav className="flex items-center text-sm font-medium text-slate-400">
          <Link to="/" className="hover:text-white transition-colors">SACDIA</Link>
          {pathParts.length > 0 && <ChevronRight size={14} className="mx-2 text-slate-600" />}
          {pathParts.map((part, i) => (
            <React.Fragment key={part}>
              <span className="capitalize text-slate-200">{part.replace('-', ' ')}</span>
              {i < pathParts.length - 1 && <ChevronRight size={14} className="mx-2 text-slate-600" />}
            </React.Fragment>
          ))}
        </nav>
      </div>
      <div className="flex items-center gap-6">
        <div className="relative">
          <Search className="absolute left-3 top-2.5 text-slate-500" size={18} />
          <input 
            className="pl-10 pr-4 py-2 text-sm bg-slate-900 border border-slate-800 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#2b2bee] w-64 placeholder-slate-600 text-white" 
            placeholder="Search records..." 
            type="text"
          />
        </div>
        <button className="relative p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-full transition-colors">
          <Bell size={20} />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border-2 border-[#101022]"></span>
        </button>
      </div>
    </header>
  );
};

const App: React.FC = () => {
  return (
    <HashRouter>
      <div className="flex h-screen overflow-hidden bg-[#101022]">
        <Sidebar />
        <div className="flex-1 flex flex-col relative overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto custom-scrollbar p-8">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/approvals" element={<MemberApprovals />} />
              <Route path="/geographical" element={<GeographicalHierarchy />} />
              <Route path="/members" element={<ClubMembers />} />
              <Route path="/events" element={<EventManagement />} />
              <Route path="/curriculum" element={<CurriculumManagement />} />
              <Route path="/scoring" element={<LiveScoring />} />
              <Route path="/roles-matrix" element={<RolesPermissions />} />
              <Route path="/catalog/roles" element={<RolesCatalog />} />
              <Route path="/catalog/permissions" element={<PermissionsCatalog />} />
              <Route path="/credentials" element={<IDGenerator />} />
              <Route path="/settings" element={<SettingsPage />} />
              <Route path="*" element={<Dashboard />} />
            </Routes>
          </main>
        </div>
      </div>
    </HashRouter>
  );
};

export default App;
