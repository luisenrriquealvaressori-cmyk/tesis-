import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useEffect, useRef, useState } from 'react';
import { fetchAlertas } from '../../services/api';

const routeLabels: Record<string, string> = {
  '/': 'Dashboard',
  '/farms': 'Mapa de Fincas',
  '/animals': 'Panel de Animales',
  '/farmers': 'Padrón de Ganaderos',
  '/reports': 'Reportes y Estadísticas',
  '/catalogs': 'Catálogos Maestros',
  '/sync-logs': 'Auditoría Sync',
  '/settings/users': 'Gestión de Usuarios',
};

const TIPO_STYLES: Record<string, { bg: string; icon: string; color: string }> = {
  sanitaria: { bg: 'bg-rose-50 border-rose-100', icon: 'medical_services', color: 'text-rose-600' },
  sync: { bg: 'bg-amber-50 border-amber-100', icon: 'sync_problem', color: 'text-amber-600' },
  nuevo_ganadero: { bg: 'bg-emerald-50 border-emerald-100', icon: 'person_add', color: 'text-emerald-600' },
};

const Header = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { nombre, rol, logout } = useAuth();
  const [alertas, setAlertas] = useState<any[]>([]);
  const [showNotif, setShowNotif] = useState(false);
  const notifRef = useRef<HTMLDivElement>(null);

  // Determinar la etiqueta de la ruta actual
  const matchedLabel = Object.entries(routeLabels).find(([path]) => {
    if (path === '/') return location.pathname === '/';
    return location.pathname.startsWith(path);
  });
  const currentLabel = matchedLabel ? matchedLabel[1] : 'Página';

  const initials = nombre
    ? nombre.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
    : 'AG';

  const handleLogout = () => { logout(); navigate('/login'); };

  // Cargar alertas
  useEffect(() => {
    fetchAlertas().then(setAlertas).catch(() => {});
  }, []);

  // Cerrar al hacer clic fuera
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) {
        setShowNotif(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const sanitarias = alertas.filter(a => a.tipo === 'sanitaria').length;
  const totalAlertas = alertas.length;

  return (
    <header className="flex justify-between items-center w-full h-16 px-gutter bg-surface border-b border-outline-variant z-40 shrink-0 animate-fade-in">
      
      {/* ── Left: Breadcrumb ─────────────────────────────── */}
      <div className="flex items-center gap-md">
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
        
        {/* Notifications panel */}
        <div className="relative" ref={notifRef}>
          <button
            onClick={() => setShowNotif(v => !v)}
            className="text-on-surface-variant hover:bg-surface-container-low transition-colors p-2 rounded-full relative"
            title={`${totalAlertas} alertas activas`}
          >
            <span className="material-symbols-outlined text-[22px]" style={{ fontVariationSettings: showNotif ? "'FILL' 1" : "" }}>notifications</span>
            {totalAlertas > 0 && (
              <span className="absolute top-1 right-1 w-4 h-4 bg-rose-500 rounded-full text-white text-[9px] font-black flex items-center justify-center">
                {totalAlertas > 9 ? '9+' : totalAlertas}
              </span>
            )}
          </button>

          {showNotif && (
            <div className="absolute right-0 top-full mt-2 w-80 bg-white rounded-2xl shadow-2xl border border-slate-200 z-50 animate-scale-in overflow-hidden">
              <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between">
                <span className="font-bold text-slate-900 text-sm" style={{ fontFamily: 'Outfit, sans-serif' }}>Alertas del Sistema</span>
                {sanitarias > 0 && (
                  <span className="text-xs font-bold bg-rose-100 text-rose-700 px-2 py-0.5 rounded-full">{sanitarias} sanitaria{sanitarias > 1 ? 's' : ''}</span>
                )}
              </div>
              <div className="overflow-y-auto custom-scrollbar" style={{ maxHeight: '360px' }}>
                {alertas.length === 0 ? (
                  <div className="py-10 text-center">
                    <span className="material-symbols-outlined text-slate-300 text-4xl block mb-2">check_circle</span>
                    <p className="text-slate-400 text-sm">Sin alertas activas</p>
                  </div>
                ) : alertas.map((a, i) => {
                  const style = TIPO_STYLES[a.tipo] ?? TIPO_STYLES.sanitaria;
                  return (
                    <div
                      key={i}
                      className={`flex items-start gap-3 p-3 border-b border-slate-50 hover:bg-slate-50 transition-colors cursor-pointer ${i === 0 ? '' : ''}`}
                      onClick={() => { if (a.fincaId) navigate(`/farms/${a.fincaId}`); setShowNotif(false); }}
                    >
                      <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${style.bg} border`}>
                        <span className={`material-symbols-outlined text-[16px] ${style.color}`} style={{ fontVariationSettings: "'FILL' 1" }}>{style.icon}</span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-bold text-slate-900">{a.titulo}</p>
                        <p className="text-xs text-slate-500 truncate mt-0.5">{a.descripcion}</p>
                        <p className="text-[10px] text-slate-400 mt-1">{new Date(a.fecha).toLocaleString('es-NI', { dateStyle: 'short', timeStyle: 'short' })}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
              {alertas.length > 0 && (
                <div className="p-3 bg-slate-50 border-t border-slate-100 text-center">
                  <button onClick={() => { navigate('/sync-logs'); setShowNotif(false); }}
                    className="text-xs text-emerald-700 font-bold hover:underline">
                    Ver auditoría completa →
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

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
