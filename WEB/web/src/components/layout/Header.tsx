import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const routeLabels: Record<string, string> = {
  '/': 'Dashboard',
  '/farms': 'Mapa de Fincas',
  '/farmers': 'Padrón de Ganaderos',
  '/catalogs': 'Catálogos Maestros',
  '/sync-logs': 'Auditoría Sync',
};

const Header = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { nombre, rol, logout } = useAuth();

  const currentLabel = routeLabels[location.pathname] ?? 'Página';
  const initials = nombre
    ? nombre.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
    : 'AG';

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <header className="flex justify-between items-center w-full h-16 px-gutter bg-surface border-b border-outline-variant z-40 shrink-0 animate-fade-in">
      
      {/* ── Left: Breadcrumb ─────────────────────────────── */}
      <div className="flex items-center gap-md">
        {/* Mobile menu toggle */}
        <button className="md:hidden p-sm text-on-surface-variant hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined">menu</span>
        </button>
        <h1 className="md:hidden font-headline-lg-mobile text-headline-lg-mobile font-black text-primary ml-sm" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>AgroControl</h1>
        
        {/* Breadcrumb (desktop only) */}
        <div className="hidden md:flex items-center gap-2 text-sm">
          <span className="text-on-surface-variant font-medium">AgroControl</span>
          <span className="text-outline">/</span>
          <span className="font-semibold text-on-surface">{currentLabel}</span>
        </div>
      </div>

      {/* ── Center: Search ───────────────────────────────── */}
      <div className="hidden md:flex items-center bg-surface-container-low border border-outline-variant rounded-xl px-md h-10 w-80 input-focus transition-all duration-200 group">
        <span className="material-symbols-outlined text-outline mr-sm text-[20px] group-focus-within:text-secondary transition-colors">search</span>
        <input 
          className="bg-transparent border-none outline-none focus:ring-0 w-full font-body-md text-body-md text-on-surface placeholder-outline p-0" 
          placeholder="Buscar fincas, ganaderos..." 
          type="text" 
        />
      </div>
      
      {/* ── Right: Actions + User ────────────────────────── */}
      <div className="flex items-center gap-3 ml-auto md:ml-0">
        
        {/* Notifications */}
        <button className="text-on-surface-variant hover:bg-surface-container-low transition-colors p-2 rounded-full relative" title="Notificaciones">
          <span className="material-symbols-outlined text-[22px]">notifications</span>
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-error rounded-full animate-pulse"></span>
        </button>

        {/* User avatar + info (desktop) */}
        <div className="hidden md:flex items-center gap-2 pl-3 border-l border-outline-variant">
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center text-white font-bold text-xs shrink-0">
            {initials}
          </div>
          <div className="leading-tight">
            <p className="text-xs font-semibold text-on-surface truncate max-w-[120px]">{nombre || 'Administrador'}</p>
            <p className="text-[11px] text-on-surface-variant">{rol || 'Supervisor'}</p>
          </div>
          <button
            onClick={handleLogout}
            title="Cerrar sesión"
            className="ml-1 p-1.5 rounded-lg text-on-surface-variant hover:bg-rose-50 hover:text-rose-600 transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">logout</span>
          </button>
        </div>
      </div>
    </header>
  );
};

export default Header;
