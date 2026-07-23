import { useEffect, useState } from 'react';
import { fetchKpis, fetchMapaFincas } from '../services/api';

const Dashboard = () => {
  const [kpis, setKpis] = useState({ totalFincas: 0, totalVacas: 0, alertasMedicas: 0 });
  const [fincas, setFincas] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      try {
        const [kpiData, fincasData] = await Promise.all([
          fetchKpis(),
          fetchMapaFincas()
        ]);
        setKpis(kpiData);
        setFincas(fincasData);
      } catch (error) {
        console.error("Failed to load dashboard data", error);
      } finally {
        setLoading(false);
      }
    };
    
    loadData();
  }, []);

  return (
    <div className="flex flex-col gap-gutter">
      {/* KPIs Row */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-md md:gap-gutter">
        {/* KPI 1 */}
        <div className="glass-card rounded-2xl p-lg shadow-sm card-hover-effect flex items-center justify-between border border-emerald-100/60 relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-24 h-24 bg-gradient-to-bl from-emerald-100/50 to-transparent rounded-bl-full pointer-events-none"></div>
          <div>
            <div className="flex items-center gap-2 mb-sm">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
              <p className="font-label-md text-label-md text-emerald-800 uppercase tracking-wider font-bold">Total Fincas Registradas</p>
            </div>
            <h3 className="font-headline-xl text-headline-xl text-primary font-black tracking-tight">
              {loading ? '...' : kpis.totalFincas}
            </h3>
            <p className="text-xs text-emerald-600 font-medium mt-1">Sincronizado con Neon DB</p>
          </div>
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-700 flex items-center justify-center text-white shadow-lg shadow-emerald-700/20 group-hover:scale-110 transition-transform">
            <span className="material-symbols-outlined icon-fill" style={{ fontSize: '30px' }}>landscape</span>
          </div>
        </div>

        {/* KPI 2 */}
        <div className="glass-card rounded-2xl p-lg shadow-sm card-hover-effect flex items-center justify-between border border-teal-100/60 relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-24 h-24 bg-gradient-to-bl from-teal-100/50 to-transparent rounded-bl-full pointer-events-none"></div>
          <div>
            <div className="flex items-center gap-2 mb-sm">
              <span className="w-2 h-2 rounded-full bg-teal-500"></span>
              <p className="font-label-md text-label-md text-teal-800 uppercase tracking-wider font-bold">Total Ganado Monitoreado</p>
            </div>
            <h3 className="font-headline-xl text-headline-xl text-primary font-black tracking-tight">
              {loading ? '...' : kpis.totalVacas}
            </h3>
            <p className="text-xs text-teal-600 font-medium mt-1">Censo Bovino Activo</p>
          </div>
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-teal-600 to-emerald-800 flex items-center justify-center text-white shadow-lg shadow-teal-700/20 group-hover:scale-110 transition-transform">
            <span className="material-symbols-outlined icon-fill" style={{ fontSize: '30px' }}>pets</span>
          </div>
        </div>

        {/* KPI 3 */}
        <div className="glass-card rounded-2xl p-lg shadow-sm card-hover-effect flex items-center justify-between border border-amber-200/60 relative overflow-hidden group">
          <div className="absolute left-0 top-0 bottom-0 w-1.5 bg-gradient-to-b from-amber-500 to-rose-600"></div>
          <div className="pl-2">
            <div className="flex items-center gap-2 mb-sm">
              <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
              <p className="font-label-md text-label-md text-amber-900 uppercase tracking-wider font-bold">Alertas Médicas (72h)</p>
            </div>
            <h3 className="font-headline-xl text-headline-xl text-rose-600 font-black tracking-tight">
              {loading ? '...' : kpis.alertasMedicas}
            </h3>
            <p className="text-xs text-rose-600/80 font-medium mt-1">Casos clínicos recientes</p>
          </div>
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-amber-500 to-rose-600 flex items-center justify-center text-white shadow-lg shadow-rose-600/20 group-hover:scale-110 transition-transform">
            <span className="material-symbols-outlined icon-fill" style={{ fontSize: '30px' }}>warning</span>
          </div>
        </div>
      </div>

      {/* Map Section */}
      <div className="flex-1 bg-surface-container-lowest border border-outline-variant rounded-lg shadow-sm min-h-[500px] flex flex-col relative overflow-hidden">
        <div className="px-md py-sm border-b border-outline-variant bg-surface-bright flex justify-between items-center z-10">
          <h3 className="font-title-md text-title-md text-primary">Mapa Interactivo - Visión Estratégica</h3>
          <div className="flex gap-sm">
            <button className="px-sm py-xs bg-secondary text-on-secondary rounded font-label-md text-label-md shadow-sm">Satélite</button>
            <button className="px-sm py-xs bg-surface text-primary border border-outline-variant rounded font-label-md text-label-md hover:bg-surface-container-low transition-colors">Relieve</button>
          </div>
        </div>

        {/* Map Container */}
        <div className="flex-1 relative bg-[#e5e5e5] flex items-center justify-center overflow-hidden">
          <img 
            className="absolute inset-0 w-full h-full object-cover opacity-80" 
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuDNu0mGMxtfsBnxLK0LuppFMV22uwEE64uP0PHhEkgzGDNHR9cqHNT08dt9FmB0qUEZuVIbgyYFfF-a5wvwPEfTFOrv6mBmVx8InYL294zx6ngkTL_VM9prhpNnZVvqwta3mHHoP725DcoYt9h4gloljZOzMc5QH89m26OR7x25favD3oh5jBxMiAKjVJb94JlmmRcazUL8bLnf0G8xwxdqhhpFyUkOlQ_MTJc4sryZlp_PL7kzXjezaCh8WkIqx8OBvImI6hnfx9Ht" 
            alt="Map Background"
          />
          
          <div className="absolute right-4 bottom-4 flex flex-col gap-2 bg-surface-container-lowest p-2 border border-outline-variant rounded shadow-md z-10">
            <button className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:bg-surface-container-low rounded">
              <span className="material-symbols-outlined">add</span>
            </button>
            <hr className="border-outline-variant border-t" />
            <button className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:bg-surface-container-low rounded">
              <span className="material-symbols-outlined">remove</span>
            </button>
          </div>

          {/* Marcadores Dinámicos */}
          {fincas.map((finca, index) => {
            // Posicionamiento simulado aleatorio para demo, idealmente usaríamos las lat/lng reales
            // con un componente de mapa como Leaflet o Google Maps
            const top = 20 + (index * 15) % 60;
            const left = 20 + (index * 25) % 60;
            const isAlert = finca.tieneAlertasSanitarias;

            return (
              <div key={finca.id} style={{ top: `${top}%`, left: `${left}%` }} className="absolute z-10 group">
                {/* Pin */}
                <div className={`w-4 h-4 rounded-full border-2 border-surface-container-lowest shadow-sm cursor-pointer transition-transform group-hover:scale-125 ${isAlert ? 'bg-error animate-pulse' : 'bg-secondary'}`}></div>
                
                {/* Tooltip Dinámico */}
                <div className="hidden group-hover:block absolute bottom-full mb-2 left-1/2 -translate-x-1/2 bg-surface-container-lowest border border-outline-variant rounded-lg p-md shadow-lg z-20 w-64">
                  <div className="flex justify-between items-start mb-sm">
                    <h4 className="font-title-md text-title-md text-primary">{finca.nombre}</h4>
                  </div>
                  <div className="flex flex-col gap-xs mb-sm">
                    <div className="flex items-center gap-xs text-on-surface-variant font-body-md text-body-md">
                      <span className="material-symbols-outlined" style={{ fontSize: '16px' }}>pets</span>
                      <span>{finca.totalGanado} vacas</span>
                    </div>
                    {isAlert && (
                      <div className="flex items-center gap-xs text-error font-body-md text-body-md">
                        <span className="material-symbols-outlined" style={{ fontSize: '16px' }}>warning</span>
                        <span>Última alerta: {finca.ultimaAlerta || 'Desconocida'}</span>
                      </div>
                    )}
                  </div>
                  <button className="w-full py-xs border border-secondary text-secondary rounded font-label-md text-label-md hover:bg-secondary hover:text-on-secondary transition-colors">
                    Ver Detalles
                  </button>
                  <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 w-4 h-4 bg-surface-container-lowest border-b border-r border-outline-variant transform rotate-45"></div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
