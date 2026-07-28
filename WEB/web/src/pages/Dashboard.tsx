import { useEffect, useState, useCallback } from 'react';
import { fetchKpis, fetchMapaFincas, fetchProduccionTendencia } from '../services/api';

// ── Skeleton Loader ─────────────────────────────────────────────────────────
const KpiSkeleton = () => (
  <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-100 flex items-center justify-between">
    <div className="flex flex-col gap-2 flex-1">
      <div className="skeleton h-3 w-24 rounded"></div>
      <div className="skeleton h-7 w-16 rounded"></div>
      <div className="skeleton h-2.5 w-32 rounded"></div>
    </div>
    <div className="skeleton w-12 h-12 rounded-xl"></div>
  </div>
);

const RowSkeleton = () => (
  <tr>
    {[1,2,3,4,5].map(i => (
      <td key={i} className="py-3 px-3">
        <div className="skeleton h-3.5 rounded w-full"></div>
      </td>
    ))}
  </tr>
);

const BarSkeleton = () => (
  <div className="flex items-center gap-3">
    <div className="skeleton h-3 w-12 rounded"></div>
    <div className="skeleton h-4 flex-1 rounded-full"></div>
    <div className="skeleton h-3 w-20 rounded"></div>
  </div>
);

// ── KPI Card ────────────────────────────────────────────────────────────────
interface KpiCardProps {
  label: string;
  value: string;
  sub: string;
  icon: string;
  colorClass: string;
  borderClass: string;
  delay?: string;
}
const KpiCard = ({ label, value, sub, icon, colorClass, borderClass, delay = '' }: KpiCardProps) => (
  <div className={`bg-white rounded-2xl p-5 shadow-sm border ${borderClass} flex items-center justify-between hover:shadow-md card-hover-effect animate-slide-up ${delay}`}>
    <div>
      <p className={`text-xs font-bold uppercase tracking-wider mb-1 ${colorClass}`}>{label}</p>
      <h3 className={`text-2xl font-black ${colorClass.replace('800','900').replace('700','900')}`}>{value}</h3>
      <p className={`text-xs font-medium mt-1 ${colorClass}`}>{sub}</p>
    </div>
    <div className={`w-12 h-12 rounded-xl ${colorClass.replace('text-','bg-').replace('-800','').replace('-700','').replace('-600','')}-100 ${colorClass} flex items-center justify-center shrink-0`}>
      <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>{icon}</span>
    </div>
  </div>
);

// ── Main Component ──────────────────────────────────────────────────────────
const Dashboard = () => {
  const [kpis, setKpis] = useState({
    totalFincas: 0, totalVacas: 0, totalUGM: 0, alertasMedicas: 0,
    produccionHoyLitros: 0, produccionHoyKg: 0, promedioLitrosVaca: 0
  });
  const [tendencia, setTendencia] = useState<any[]>([]);
  const [fincas, setFincas] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const loadData = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    try {
      const [kpiData, fincasData, tendenciaData] = await Promise.all([
        fetchKpis(), fetchMapaFincas(), fetchProduccionTendencia()
      ]);
      setKpis(kpiData);
      setFincas(fincasData);
      setTendencia(tendenciaData);
      setLastUpdated(new Date());
    } catch (error) {
      console.error('Failed to load dashboard data', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { loadData(); }, [loadData]);

  const maxTendencia = tendencia.length > 0 ? Math.max(...tendencia.map(t => t.litros), 10) : 10;

  return (
    <div className="flex flex-col gap-6">
      
      {/* ── Banner ─────────────────────────────────────────── */}
      <div className="rounded-2xl bg-gradient-to-r from-[#012d1d] via-[#0b4d34] to-[#125c40] p-6 text-white shadow-xl relative overflow-hidden animate-fade-in">
        <div className="absolute right-0 top-0 w-96 h-96 bg-emerald-400/10 rounded-full blur-3xl pointer-events-none"></div>
        <div className="absolute -left-8 -bottom-8 w-48 h-48 bg-teal-400/5 rounded-full blur-2xl pointer-events-none"></div>
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 relative z-10">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/20 border border-emerald-400/30 text-emerald-300 text-xs font-bold mb-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              Plataforma Institucional de Monitoreo Ganadero
            </div>
            <h2 className="text-3xl font-extrabold tracking-tight" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
              Centro de Control de Hato &amp; Bioseguridad
            </h2>
            <p className="text-emerald-100/80 text-sm mt-1">
              Supervisión en tiempo real de producción láctea, censo bovino y retiros sanitarios.
            </p>
            {lastUpdated && (
              <p className="text-emerald-300/50 text-xs mt-2 font-mono">
                Última actualización: {lastUpdated.toLocaleTimeString('es-NI')}
              </p>
            )}
          </div>
          <div className="flex items-center gap-3">
            <div className="bg-emerald-950/60 border border-emerald-700/50 px-4 py-2 rounded-xl text-center">
              <p className="text-[11px] text-emerald-300 uppercase font-bold tracking-wider">Densidad Leche</p>
              <p className="text-lg font-black text-white">1.032 kg/L</p>
            </div>
            <button
              onClick={() => loadData(true)}
              disabled={refreshing}
              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-500/20 border border-emerald-400/30 text-emerald-300 text-xs font-bold hover:bg-emerald-500/30 transition-all disabled:opacity-50"
              title="Actualizar datos"
            >
              <span className={`material-symbols-outlined text-[18px] ${refreshing ? 'animate-spin' : ''}`}>refresh</span>
              {refreshing ? 'Actualizando...' : 'Actualizar'}
            </button>
          </div>
        </div>
      </div>

      {/* ── KPI Grid ─────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {loading ? (
          [1,2,3,4].map(i => <KpiSkeleton key={i} />)
        ) : (
          <>
            <KpiCard
              label="Total Fincas"
              value={String(kpis.totalFincas)}
              sub="Propiedades registradas"
              icon="landscape"
              colorClass="text-emerald-800"
              borderClass="border-emerald-100"
              delay="delay-75"
            />
            <KpiCard
              label="Ganado / UGM"
              value={`${kpis.totalVacas} cab`}
              sub={`${kpis.totalUGM} UGM Totales`}
              icon="pets"
              colorClass="text-teal-700"
              borderClass="border-teal-100"
              delay="delay-150"
            />
            <KpiCard
              label="Producción Hoy"
              value={`${kpis.produccionHoyLitros} L`}
              sub={`${kpis.produccionHoyKg} kg · ${kpis.promedioLitrosVaca} L/vaca`}
              icon="water_drop"
              colorClass="text-blue-700"
              borderClass="border-blue-100"
              delay="delay-225"
            />
            <div className={`bg-white rounded-2xl p-5 shadow-sm border ${kpis.alertasMedicas > 0 ? 'border-rose-200 ring-2 ring-rose-100' : 'border-slate-100'} flex items-center justify-between hover:shadow-md card-hover-effect animate-slide-up delay-300`}>
              <div>
                <p className="text-xs font-bold text-rose-700 uppercase tracking-wider mb-1">Alertas Sanitarias</p>
                <h3 className={`text-2xl font-black ${kpis.alertasMedicas > 0 ? 'text-rose-600' : 'text-slate-400'}`}>
                  {kpis.alertasMedicas}
                </h3>
                <p className="text-xs text-rose-600 font-medium mt-1">Casos clínicos activos (72h)</p>
              </div>
              <div className={`w-12 h-12 rounded-xl ${kpis.alertasMedicas > 0 ? 'bg-rose-100' : 'bg-slate-100'} flex items-center justify-center`}>
                <span className={`material-symbols-outlined text-2xl ${kpis.alertasMedicas > 0 ? 'text-rose-600' : 'text-slate-400'}`} style={{ fontVariationSettings: "'FILL' 1" }}>
                  {kpis.alertasMedicas > 0 ? 'warning' : 'check_circle'}
                </span>
              </div>
            </div>
          </>
        )}
      </div>

      {/* ── Tendencia + Tabla Fincas ─────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Tendencia semanal */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200 flex flex-col justify-between animate-slide-up delay-150">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-slate-900 text-lg flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
                <span className="material-symbols-outlined text-emerald-600">show_chart</span>
                Tendencia Semanal
              </h3>
              <span className="text-xs font-semibold px-2.5 py-1 bg-emerald-100 text-emerald-800 rounded-full">Últimos 7 días</span>
            </div>
            <p className="text-xs text-slate-500 mb-5">Volumen diario consolidado de leche entregada por las fincas.</p>

            <div className="space-y-3.5">
              {loading ? (
                [1,2,3,4,5,6,7].map(i => <BarSkeleton key={i} />)
              ) : tendencia.length === 0 ? (
                <div className="text-center py-6">
                  <span className="material-symbols-outlined text-slate-300 text-5xl">bar_chart</span>
                  <p className="text-sm text-slate-400 italic mt-2">No hay datos de ordeño esta semana.</p>
                </div>
              ) : (
                tendencia.map((item, idx) => {
                  const pct = Math.min(100, Math.round((item.litros / maxTendencia) * 100));
                  return (
                    <div key={idx} className="flex items-center gap-3 text-xs group">
                      <span className="w-12 text-slate-500 font-bold shrink-0">{item.fecha}</span>
                      <div className="flex-1 bg-slate-100 h-5 rounded-full overflow-hidden">
                        <div
                          className="bg-gradient-to-r from-emerald-500 to-teal-600 h-full rounded-full transition-all duration-700 ease-out"
                          style={{ width: `${pct}%` }}
                        ></div>
                      </div>
                      <span className="w-24 text-right font-black text-slate-700 tabular-nums shrink-0">
                        {item.litros}L
                        <span className="text-slate-400 font-normal ml-0.5 text-[10px]">({item.kg}kg)</span>
                      </span>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between text-xs font-semibold text-slate-600">
            <span>Promedio por Vaca:</span>
            <span className="text-emerald-700 font-bold text-sm">
              {loading ? <span className="skeleton inline-block w-20 h-4 rounded"></span> : `${kpis.promedioLitrosVaca} L/vaca/día`}
            </span>
          </div>
        </div>

        {/* Tabla de fincas */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-slate-200 flex flex-col animate-slide-up delay-225">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-slate-900 text-lg flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
              <span className="material-symbols-outlined text-teal-600" style={{ fontVariationSettings: "'FILL' 1" }}>map</span>
              Resumen Geográfico de Fincas &amp; Hato
            </h3>
            <span className="text-xs font-semibold px-2.5 py-1 bg-slate-100 text-slate-600 rounded-full">
              {loading ? '…' : `${fincas.length} fincas activas`}
            </span>
          </div>

          <div className="overflow-x-auto flex-1">
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
                {loading ? (
                  [1,2,3,4].map(i => <RowSkeleton key={i} />)
                ) : fincas.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-12 text-center">
                      <span className="material-symbols-outlined text-slate-300 text-5xl block mb-2">domain_disabled</span>
                      <p className="text-slate-400 italic text-sm">No hay fincas registradas aún.</p>
                      <p className="text-slate-300 text-xs mt-1">Los ganaderos deben sincronizar la app móvil.</p>
                    </td>
                  </tr>
                ) : (
                  fincas.map((finca) => (
                    <tr key={finca.id} className="hover:bg-emerald-50/40 transition-colors group">
                      <td className="py-3 px-3 font-bold text-slate-900">
                        <div className="flex items-center gap-2">
                          <span className="material-symbols-outlined text-emerald-600 text-base group-hover:scale-110 transition-transform" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
                          {finca.nombre}
                        </div>
                      </td>
                      <td className="py-3 px-3 text-slate-700 font-medium">{finca.ganaderoNombre}</td>
                      <td className="py-3 px-3 text-slate-500">{finca.municipio}{finca.comarca ? ` · ${finca.comarca}` : ''}</td>
                      <td className="py-3 px-3 text-center">
                        <span className="font-bold text-slate-800">{finca.totalGanado} cab</span>
                        <span className="text-slate-400 text-[10px] ml-1">({finca.totalUGM} UGM)</span>
                      </td>
                      <td className="py-3 px-3 text-center">
                        {finca.tieneAlertasSanitarias ? (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-rose-100 text-rose-700 font-bold text-[10px]">
                            <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-pulse"></span>
                            {finca.ultimaAlerta || 'Alerta Sanitaria'}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 font-bold text-[10px]">
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
