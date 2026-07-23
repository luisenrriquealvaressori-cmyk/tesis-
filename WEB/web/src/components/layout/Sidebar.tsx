import { Link, useLocation } from 'react-router-dom';

const Sidebar = () => {
  const location = useLocation();

  const navItems = [
    { name: 'Dashboard', path: '/', icon: 'dashboard', fill: false },
    { name: 'Mapa de Fincas', path: '/farms', icon: 'map', fill: true },
    { name: 'Inventario Ganadero', path: '/inventory', icon: 'pets', fill: false },
    { name: 'Configuración', path: '/catalogs', icon: 'settings', fill: true }
  ];

  return (
    <nav className="hidden md:flex flex-col py-lg fixed left-0 top-0 h-full w-sidebar-width bg-gradient-to-b from-[#012d1d] to-[#0d3b28] z-50 border-r border-emerald-800/30 shadow-xl">
      <div className="px-md mb-xl flex items-center gap-md">
        <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-emerald-400 to-teal-600 flex items-center justify-center shrink-0 shadow-lg shadow-emerald-900/40">
          <span className="material-symbols-outlined text-white text-[26px]" style={{ fontVariationSettings: "'FILL' 1" }}>agriculture</span>
        </div>
        <div>
          <h1 className="font-headline-lg text-headline-lg font-extrabold text-white tracking-tight">AgroControl</h1>
          <div className="flex items-center gap-1.5 mt-0.5">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <p className="font-label-sm text-label-sm text-emerald-200/80 font-medium">Control Tower Live</p>
          </div>
        </div>
      </div>
      
      <div className="flex-1 flex flex-col gap-1.5 overflow-y-auto custom-scrollbar px-sm">
        <p className="px-md text-[10px] font-bold text-emerald-400/60 uppercase tracking-widest mb-1">Navegación Principal</p>
        {navItems.map((item) => {
          const isActive = location.pathname === item.path || (item.path !== '/' && location.pathname.startsWith(item.path));
          
          if (isActive) {
            return (
              <Link 
                key={item.path} 
                to={item.path} 
                className="flex items-center gap-md bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-xl p-sm mx-xs font-bold shadow-md shadow-emerald-900/30 transition-all duration-200"
              >
                <span className="material-symbols-outlined text-[22px]" style={{ fontVariationSettings: item.fill ? "'FILL' 1" : "" }}>{item.icon}</span>
                <span className="font-label-md text-label-md text-white">{item.name}</span>
              </Link>
            );
          }
          
          return (
            <Link 
              key={item.path} 
              to={item.path} 
              className="flex items-center gap-md text-emerald-100/70 hover:bg-emerald-800/40 p-sm mx-xs rounded-xl transition-all duration-150 hover:text-white group"
            >
              <span className="material-symbols-outlined text-[22px] group-hover:scale-110 transition-transform">{item.icon}</span>
              <span className="font-label-md text-label-md">{item.name}</span>
            </Link>
          );
        })}
      </div>
      
      <div className="px-md mt-auto pt-md border-t border-emerald-800/40">
        <div className="flex items-center gap-md p-sm rounded-xl bg-emerald-950/40 border border-emerald-800/30">
          <img alt="Administrator Profile" className="w-9 h-9 rounded-full object-cover border-2 border-emerald-400/50 shadow-sm" src="https://lh3.googleusercontent.com/aida-public/AB6AXuB_MUOVLXQGIlqpUpyCYIIchtWr7HRGiGj7afVNFm3kR55hzB_XUQAvXmrO_9ZzepcMW91bjALpNCv0C2AiO7-emGIsGASI4bTwXWUKkcV-JxfzyIn6UOk4xHc4vAaLGA4vhrylcRtI5yy6FpVyjeff2HfQfULT6MZdGRGH3idMqBVOIDX5vmR3u1EDB0n9N6xk6v8lAeSq3GCC-U2jRbO42zRho4RtUY_U7xbzoGeVM4wUKlRnw4mgw8Im_BvAxFnjyORe2rtrCXIN" />
          <div className="overflow-hidden">
            <p className="font-label-md text-label-md text-white font-semibold truncate">Admin General</p>
            <p className="font-label-sm text-[11px] text-emerald-300/80 truncate">admin@agrostats.org</p>
          </div>
        </div>
      </div>
    </nav>
  );
};

export default Sidebar;
