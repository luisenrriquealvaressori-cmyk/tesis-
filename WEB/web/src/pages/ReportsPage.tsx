import { useEffect, useState } from 'react';
import { fetchReportes } from '../services/api';

const BarRow = ({ label, value, max, color = 'emerald' }: { label: string; value: number; max: number; color?: string }) => {
  const pct = max > 0 ? Math.min(100, Math.round((value / max) * 100)) : 0;
  return (
    <div className="flex items-center gap-3 text-xs">
      <span className="w-24 text-slate-600 font-semibold truncate shrink-0">{label}</span>
      <div className="flex-1 bg-slate-100 h-5 rounded-full overflow-hidden">
        <div className={`bg-gradient-to-r from-${color}-500 to-${color}-600 h-full rounded-full transition-all duration-700`} style={{ width: `${pct}%` }}></div>
      </div>
      <span className="w-16 text-right font-black text-slate-700 tabular-nums shrink-0">{value.toLocaleString()}</span>
    </div>
  );
};

const ReportsPage = () => {
  const [data, setData] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchReportes().then(setData).catch(console.error).finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col gap-6 animate-fade-in">
        {[1,2,3].map(i => <div key={i} className="skeleton h-48 rounded-2xl"></div>)}
      </div>
    );
  }

  const maxProd = data?.produccionMensual ? Math.max(...data.produccionMensual.map((p: any) => p.litros), 1) : 1;
  const maxEnf = data?.enfermedadesFrecuentes ? Math.max(...data.enfermedadesFrecuentes.map((e: any) => e.totalCasos), 1) : 1;
  const maxRank = data?.rankingFincas ? Math.max(...data.rankingFincas.map((r: any) => r.litrosTotales), 1) : 1;
  const censo = data?.censoGanadero;
  const totalCenso = censo ? censo.totalHembras + censo.totalMachos : 0;

  return (
    <div className="flex flex-col gap-6 animate-fade-in">

      {/* ── Header ──────────────────────────────────────── */}
      <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200">
        <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
          <span className="material-symbols-outlined text-violet-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>bar_chart</span>
          Reportes y Estadísticas
        </h2>
        <p className="text-slate-500 text-sm mt-0.5">Análisis consolidado de producción, sanidad y censo ganadero del sistema.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* ── Producción mensual ─────────────────────────── */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-200">
          <h3 className="font-bold text-slate-900 text-base flex items-center gap-2 mb-1" style={{ fontFamily: 'Outfit, sans-serif' }}>
            <span className="material-symbols-outlined text-blue-600">water_drop</span>
            Producción Mensual (Últimos 12 meses)
          </h3>
          <p className="text-xs text-slate-400 mb-4">Litros totales de leche por mes en todas las fincas.</p>
          <div className="space-y-2.5">
            {!data?.produccionMensual?.length ? (
              <p className="text-slate-400 italic text-sm">Sin datos de producción.</p>
            ) : data.produccionMensual.map((p: any, i: number) => (
              <BarRow key={i} label={p.mes} value={p.litros} max={maxProd} color="blue" />
            ))}
          </div>
        </div>

        {/* ── Enfermedades frecuentes ─────────────────────── */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-200">
          <h3 className="font-bold text-slate-900 text-base flex items-center gap-2 mb-1" style={{ fontFamily: 'Outfit, sans-serif' }}>
            <span className="material-symbols-outlined text-rose-500">medical_services</span>
            Morbilidad — Enfermedades más Frecuentes
          </h3>
          <p className="text-xs text-slate-400 mb-4">Total de casos registrados por diagnóstico.</p>
          <div className="space-y-2.5">
            {!data?.enfermedadesFrecuentes?.length ? (
              <p className="text-slate-400 italic text-sm">Sin registros de enfermedades.</p>
            ) : data.enfermedadesFrecuentes.map((e: any, i: number) => (
              <BarRow key={i} label={e.enfermedad} value={e.totalCasos} max={maxEnf} color="rose" />
            ))}
          </div>
        </div>

        {/* ── Ranking de fincas ──────────────────────────── */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-200">
          <h3 className="font-bold text-slate-900 text-base flex items-center gap-2 mb-1" style={{ fontFamily: 'Outfit, sans-serif' }}>
            <span className="material-symbols-outlined text-amber-500">emoji_events</span>
            Ranking de Fincas por Producción
          </h3>
          <p className="text-xs text-slate-400 mb-4">Top fincas por litros acumulados totales.</p>
          <div className="space-y-2.5">
            {!data?.rankingFincas?.length ? (
              <p className="text-slate-400 italic text-sm">Sin datos de producción por finca.</p>
            ) : data.rankingFincas.map((r: any, i: number) => (
              <div key={i} className="flex items-center gap-3 text-xs">
                <span className={`w-5 h-5 rounded-full flex items-center justify-center font-black text-[10px] shrink-0 ${i === 0 ? 'bg-amber-400 text-white' : i === 1 ? 'bg-slate-300 text-slate-700' : i === 2 ? 'bg-orange-300 text-white' : 'bg-slate-100 text-slate-500'}`}>{i+1}</span>
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-slate-900 truncate">{r.finca}</p>
                  <p className="text-slate-400 truncate">{r.ganadero} · {r.totalAnimales} animales</p>
                </div>
                <div className="flex-1 bg-slate-100 h-4 rounded-full overflow-hidden">
                  <div className="bg-gradient-to-r from-amber-400 to-orange-400 h-full rounded-full transition-all duration-700"
                    style={{ width: `${Math.min(100, Math.round((r.litrosTotales / maxRank) * 100))}%` }}></div>
                </div>
                <span className="w-16 text-right font-black text-slate-700 tabular-nums shrink-0">{r.litrosTotales.toLocaleString()}L</span>
              </div>
            ))}
          </div>
        </div>

        {/* ── Censo ganadero ─────────────────────────────── */}
        {censo && (
          <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-200">
            <h3 className="font-bold text-slate-900 text-base flex items-center gap-2 mb-1" style={{ fontFamily: 'Outfit, sans-serif' }}>
              <span className="material-symbols-outlined text-emerald-600">pets</span>
              Censo Ganadero General
            </h3>
            <p className="text-xs text-slate-400 mb-4">Distribución del hato por sexo, categoría y raza.</p>

            {/* Sexo */}
            <div className="grid grid-cols-2 gap-3 mb-4">
              <div className="bg-pink-50 border border-pink-100 rounded-xl p-3 text-center">
                <p className="text-2xl font-black text-pink-700">♀ {censo.totalHembras}</p>
                <p className="text-xs font-bold text-pink-500 uppercase">Hembras</p>
                <p className="text-xs text-slate-400">{totalCenso > 0 ? Math.round((censo.totalHembras / totalCenso) * 100) : 0}%</p>
              </div>
              <div className="bg-blue-50 border border-blue-100 rounded-xl p-3 text-center">
                <p className="text-2xl font-black text-blue-700">♂ {censo.totalMachos}</p>
                <p className="text-xs font-bold text-blue-500 uppercase">Machos</p>
                <p className="text-xs text-slate-400">{totalCenso > 0 ? Math.round((censo.totalMachos / totalCenso) * 100) : 0}%</p>
              </div>
            </div>

            {/* Categorías */}
            <div className="grid grid-cols-3 gap-2 mb-4">
              {[
                { label: 'Adultos', value: censo.adultos, color: 'emerald' },
                { label: 'Jóvenes', value: censo.jovenes, color: 'teal' },
                { label: 'Crías', value: censo.crias, color: 'cyan' },
              ].map(c => (
                <div key={c.label} className={`bg-${c.color}-50 border border-${c.color}-100 rounded-xl p-2.5 text-center`}>
                  <p className={`text-lg font-black text-${c.color}-700`}>{c.value}</p>
                  <p className={`text-[10px] font-bold text-${c.color}-500 uppercase`}>{c.label}</p>
                </div>
              ))}
            </div>

            {/* Por raza */}
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Distribución por Raza</p>
            <div className="space-y-1.5 max-h-36 overflow-y-auto custom-scrollbar">
              {censo.porRaza.map((r: any, i: number) => (
                <div key={i} className="flex items-center justify-between text-xs">
                  <span className="text-slate-700 font-semibold">{r.raza}</span>
                  <div className="flex items-center gap-2">
                    <div className="w-24 bg-slate-100 h-3 rounded-full overflow-hidden">
                      <div className="bg-emerald-500 h-full rounded-full" style={{ width: `${totalCenso > 0 ? Math.round((r.total/totalCenso)*100) : 0}%` }}></div>
                    </div>
                    <span className="font-bold text-slate-700 w-8 text-right">{r.total}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ReportsPage;
