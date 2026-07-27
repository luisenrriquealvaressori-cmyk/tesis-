import { useEffect, useState } from 'react';
import { fetchKpis, fetchMapaFincas, fetchProduccionTendencia } from '../services/api';

const Dashboard = () => {
  const [kpis, setKpis] = useState({
    totalFincas: 0,
    totalVacas: 0,
    totalUGM: 0,
    alertasMedicas: 0,
    produccionHoyLitros: 0,
    produccionHoyKg: 0,
    promedioLitrosVaca: 0
  });
  const [tendencia, setTendencia] = useState<any[]>([]);
  const [fincas, setFincas] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      try {
        const [kpiData, fincasData, tendenciaData] = await Promise.all([
          fetchKpis(),
          fetchMapaFincas(),
          fetchProduccionTendencia()
        ]);
        setKpis(kpiData);
        setFincas(fincasData);
        setTendencia(tendenciaData);
      } catch (error) {
        console.error("Failed to load dashboard data", error);
      } finally {
        setLoading(false);
      }
    };
    
    loadData();
  }, []);

  return (
    <div className="flex flex-col gap-6">
      {/* Banner Superior */}
      <div className="rounded-2xl bg-gradient-to-r from-[#012d1d] via-[#0b4d34] to-[#125c40] p-6 text-white shadow-xl relative overflow-hidden">
        <div className="absolute right-0 top-0 w-96 h-96 bg-emerald-400/10 rounded-full blur-3xl pointer-events-none"></div>
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 relative z-10">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/20 border border-emerald-400/30 text-emerald-300 text-xs font-bold mb-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              Plataforma Institucional de Monitoreo Ganadero
            </div>
            <h2 className="text-3xl font-extrabold tracking-tight">Centro de Control de Hato & Bioseguridad</h2>
            <p className="text-emerald-100/80 text-sm mt-1">Supervisión en tiempo real de producción láctea, censo bovino y retiros sanitarios.</p>
          </div>
          <div className="flex items-center gap-3">
            <div className="bg-emerald-950/60 border border-emerald-700/50 px-4 py-2 rounded-xl text-center">
              <p className="text-[11px] text-emerald-300 uppercase font-bold tracking-wider">Densidad Leche</p>
              <p className="text-lg font-black text-white">1.032 kg/L</p>
            </div>
          </div>
        </div>
      </div>

      {/* Grid de Métricas KPI */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Fincas */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-emerald-100 flex items-center justify-between hover:shadow-md transition-all">
          <div>
            <p className="text-xs font-bold text-emerald-800 uppercase tracking-wider mb-1">Total Fincas</p>
            <h3 className="text-2xl font-black text-slate-900">{loading ? '...' : kpis.totalFincas}</h3>
            <p className="text-xs text-slate-500 font-medium mt-1">Propiedades registradas</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-emerald-100 text-emerald-800 flex items-center justify-center">
            <span className="material-symbols-outlined text-2xl">landscape</span>
          </div>
        </div>

        {/* KPI 2: Ganado & UGM */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-teal-100 flex items-center justify-between hover:shadow-md transition-all">
          <div>
            <p className="text-xs font-bold text-teal-800 uppercase tracking-wider mb-1">Ganado / UGM</p>
            <h3 className="text-2xl font-black text-slate-900">{loading ? '...' : `${kpis.totalVacas} cab`}</h3>
            <p className="text-xs text-teal-700 font-semibold mt-1">{loading ? '...' : `${kpis.totalUGM} UGM Totales`}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-teal-100 text-teal-800 flex items-center justify-center">
            <span className="material-symbols-outlined text-2xl">pets</span>
          </div>
        </div>

        {/* KPI 3: Producción Hoy */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-blue-100 flex items-center justify-between hover:shadow-md transition-all">
          <div>
            <p className="text-xs font-bold text-blue-800 uppercase tracking-wider mb-1">Producción Hoy</p>
            <h3 className="text-2xl font-black text-blue-900">{loading ? '...' : `${kpis.produccionHoyLitros} L`}</h3>
            <p className="text-xs text-blue-700 font-semibold mt-1">{loading ? '...' : `${kpis.produccionHoyKg} kg`}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-100 text-blue-800 flex items-center justify-center">
            <span className="material-symbols-outlined text-2xl">water_drop</span>
          </div>
        </div>

        {/* KPI 4: Alertas Médicas */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-rose-100 flex items-center justify-between hover:shadow-md transition-all">
          <div>
            <p className="text-xs font-bold text-rose-800 uppercase tracking-wider mb-1">Alertas Sanitarias</p>
            <h3 className="text-2xl font-black text-rose-600">{loading ? '...' : kpis.alertasMedicas}</h3>
            <p className="text-xs text-rose-600 font-medium mt-1">Casos clínicos activos (72h)</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center">
            <span className="material-symbols-outlined text-2xl">warning</span>
          </div>
        </div>
      </div>

      {/* Tendencias de Producción y Mapa Interactivo */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Gráfico / Tabla de Tendencia */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-slate-900 text-lg flex items-center gap-2">
                <span className="material-symbols-outlined text-emerald-600">show_chart</span>
                Tendencia Semanal de Producción
              </h3>
              <span className="text-xs font-semibold px-2.5 py-1 bg-emerald-100 text-emerald-800 rounded-full">Últimos 7 días</span>
            </div>
            <p className="text-xs text-slate-500 mb-4">Volumen diario consolidado de leche entregada por las fincas.</p>

            <div className="space-y-3">
              {tendencia.length === 0 ? (
                <p className="text-sm text-slate-400 italic">No hay datos suficientes de ordeño esta semana.</p>
              ) : (
                tendencia.map((item, idx) => {
                  const maxVal = Math.max(...tendencia.map(t => t.litros), 10);
                  const percentage = Math.min(100, Math.round((item.litros / maxVal) * 100));

                  return (
                    <div key={idx} className="flex items-center gap-3 text-xs">
                      <span className="w-12 text-slate-600 font-bold">{item.fecha}</span>
                      <div className="flex-1 bg-slate-100 h-4 rounded-full overflow-hidden flex">
                        <div 
                          className="bg-gradient-to-r from-emerald-500 to-teal-600 h-full rounded-full transition-all duration-500" 
                          style={{ width: `${percentage}%` }}
                        ></div>
                      </div>
                      <span className="w-20 text-right font-black text-slate-800">{item.litros} L ({item.kg} kg)</span>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between text-xs font-semibold text-slate-600">
            <span>Promedio por Vaca:</span>
            <span className="text-emerald-700 font-bold text-sm">{kpis.promedioLitrosVaca} L/vaca/día</span>
          </div>
        </div>

        {/* Vista Visual de Fincas y Ubicaciones */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-slate-200 flex flex-col">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-slate-900 text-lg flex items-center gap-2">
              <span className="material-symbols-outlined text-teal-600">map</span>
              Resumen Geográfico de Fincas & Hato
            </h3>
            <span className="text-xs font-semibold px-2.5 py-1 bg-slate-100 text-slate-700 rounded-full">{fincas.length} fincas activas</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-slate-200 text-slate-400 font-bold uppercase tracking-wider">
                  <th className="py-2.5 px-3">Finca</th>
                  <th className="py-2.5 px-3">Ganadero</th>
                  <th className="py-2.5 px-3">Municipio / Comarca</th>
                  <th className="py-2.5 px-3 text-center">Ganado / UGM</th>
                  <th className="py-2.5 px-3 text-center">Estado Sanitario</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {fincas.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-6 text-center text-slate-400 italic">No hay fincas registradas aún.</td>
                  </tr>
                ) : (
                  fincas.map((finca) => (
                    <tr key={finca.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="py-3 px-3 font-bold text-slate-900 flex items-center gap-2">
                        <span className="material-symbols-outlined text-emerald-600 text-base">domain</span>
                        {finca.nombre}
                      </td>
                      <td className="py-3 px-3 text-slate-700 font-medium">{finca.ganaderoNombre}</td>
                      <td className="py-3 px-3 text-slate-600">{finca.municipio} {finca.comarca ? `• ${finca.comarca}` : ''}</td>
                      <td className="py-3 px-3 text-center font-bold text-slate-800">
                        {finca.totalGanado} cab ({finca.totalUGM} UGM)
                      </td>
                      <td className="py-3 px-3 text-center">
                        {finca.tieneAlertasSanitarias ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-rose-100 text-rose-700 font-bold text-[10px]">
                            <span className="w-1.5 h-1.5 rounded-full bg-rose-600 animate-pulse"></span>
                            {finca.ultimaAlerta || 'Alerta Sanitaria'}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 font-bold text-[10px]">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                            Sin novedades
                          </span>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
