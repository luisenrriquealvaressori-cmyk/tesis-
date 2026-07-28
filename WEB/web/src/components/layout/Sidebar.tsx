import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const Sidebar = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { nombre, rol, logout } = useAuth();

  const navItems = [
    { name: 'Dashboard', path: '/', icon: 'space_dashboard', fill: true },
    { name: 'Mapa de Fincas', path: '/farms', icon: 'map', fill: true },
    { name: 'Padrón de Ganaderos', path: '/farmers', icon: 'badge', fill: true },
    { name: 'Catálogos Maestros', path: '/catalogs', icon: 'clinical_notes', fill: true },
    { name: 'Auditoría Sync', path: '/sync-logs', icon: 'sync_alt', fill: true }
  ];

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  // Iniciales del nombre para el avatar
  const initials = nombre
    ? nombre.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
    : 'AG';

  return (
    <nav className="hidden md:flex flex-col py-lg fixed left-0 top-0 h-full w-sidebar-width bg-gradient-to-b from-[#012d1d] via-[#0b3d29] to-[#0d3b28] z-50 border-r border-emerald-800/30 shadow-xl">
      
      {/* ── Logo ─────────────────────────────────────────── */}
      <div className="px-md mb-xl flex items-center gap-md animate-slide-up">
        <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-emerald-400 to-teal-600 flex items-center justify-center shrink-0 shadow-lg shadow-emerald-900/40">
          <span className="material-symbols-outlined text-white text-[26px]" style={{ fontVariationSettings: "'FILL' 1" }}>agriculture</span>
        </div>
        <div>
          <h1 className="font-headline-lg text-headline-lg font-extrabold text-white tracking-tight" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>AgroControl</h1>
          <div className="flex items-center gap-1.5 mt-0.5">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <p className="font-label-sm text-label-sm text-emerald-200/80 font-medium">Control Tower Live</p>
          </div>
        </div>
      </div>
      
      {/* ── Navigation ───────────────────────────────────── */}
      <div className="flex-1 flex flex-col gap-1.5 overflow-y-auto custom-scrollbar px-sm">
        <p className="px-md text-[10px] font-bold text-emerald-400/60 uppercase tracking-widest mb-1">Navegación Principal</p>
        {navItems.map((item, idx) => {
          const isActive = location.pathname === item.path || (item.path !== '/' && location.pathname.startsWith(item.path));
          
          return (
            <Link 
              key={item.path} 
              to={item.path}
              style={{ animationDelay: `${idx * 60}ms` }}
              className={`animate-slide-in-left flex items-center gap-md p-sm mx-xs rounded-xl transition-all duration-200 group relative ${
                isActive
                  ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-md shadow-emerald-900/30 font-bold'
                  : 'text-emerald-100/70 hover:bg-emerald-800/40 hover:text-white'
              }`}
            >
              {isActive && (
                <span className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-white rounded-r-full opacity-80"></span>
              )}
              <span 
                className={`material-symbols-outlined text-[22px] transition-transform group-hover:scale-110 ${isActive ? 'scale-110' : ''}`}
                style={{ fontVariationSettings: item.fill && isActive ? "'FILL' 1" : "" }}
              >
                {item.icon}
              </span>
              <span className="font-label-md text-label-md">{item.name}</span>
            </Link>
          );
        })}
      </div>
      
      {/* ── Divider ──────────────────────────────────────── */}
      <div className="mx-md mt-auto border-t border-emerald-800/40 pt-md">
        
        {/* User info block */}
        <div className="flex items-center gap-md p-sm rounded-xl bg-emerald-950/40 border border-emerald-800/30 mb-2">
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center text-white font-bold text-sm shrink-0 shadow">
            {initials}
          </div>
          <div className="overflow-hidden flex-1">
            <p className="font-label-md text-label-md text-white font-semibold truncate">{nombre || 'Administrador'}</p>
            <p className="font-label-sm text-[11px] text-emerald-300/80 truncate">{rol || 'Supervisor'}</p>
          </div>
        </div>

        {/* Logout button */}
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-2 px-sm py-2 rounded-xl text-rose-300/80 hover:bg-rose-500/10 hover:text-rose-300 transition-all duration-150 text-xs font-semibold group"
        >
          <span className="material-symbols-outlined text-[18px] group-hover:translate-x-0.5 transition-transform">logout</span>
          Cerrar Sesión
        </button>

        {/* Version */}
        <p className="text-center text-[10px] text-emerald-600/50 mt-2 pb-1 font-mono">AgroControl v1.0</p>
      </div>
    </nav>
  );
};

export default Sidebar;
