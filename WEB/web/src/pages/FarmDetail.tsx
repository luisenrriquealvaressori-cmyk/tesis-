import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { fetchFincaDetalle } from '../services/api';

const ESTADO_STYLES: Record<string, string> = {
  Sana: 'bg-emerald-100 text-emerald-800',
  Enferma: 'bg-rose-100 text-rose-700',
  'En Tratamiento': 'bg-amber-100 text-amber-700',
};

const FarmDetail = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [detalle, setDetalle] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'animales' | 'salud' | 'produccion'>('animales');
  const [searchAnimal, setSearchAnimal] = useState('');

  useEffect(() => {
    if (!id) return;
    const load = async () => {
      try {
        const data = await fetchFincaDetalle(id);
        setDetalle(data);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [id]);

  if (loading) {
    return (
      <div className="flex flex-col gap-6 animate-fade-in">
        <div className="skeleton h-32 rounded-2xl"></div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[1,2,3,4].map(i => <div key={i} className="skeleton h-24 rounded-2xl"></div>)}
        </div>
        <div className="skeleton h-64 rounded-2xl"></div>
      </div>
    );
  }

  if (!detalle) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-4">
        <span className="material-symbols-outlined text-slate-300 text-7xl">domain_disabled</span>
        <p className="text-slate-500 text-lg font-semibold">Finca no encontrada</p>
        <button onClick={() => navigate('/farms')} className="text-emerald-600 hover:underline text-sm">← Volver al mapa</button>
      </div>
    );
  }

  const filteredAnimales = (detalle.animales || []).filter((a: any) =>
    a.identificacion.toLowerCase().includes(searchAnimal.toLowerCase()) ||
    a.raza.toLowerCase().includes(searchAnimal.toLowerCase())
  );

  const maxBar = Math.max(...(detalle.tendencia30Dias || []).map((t: any) => t.litros), 1);

  return (
    <div className="flex flex-col gap-5 animate-fade-in">

      {/* ── Breadcrumb ──────────────────────────────────── */}
      <button onClick={() => navigate('/farms')} className="flex items-center gap-1.5 text-sm text-slate-500 hover:text-emerald-600 transition-colors w-fit">
        <span className="material-symbols-outlined text-[18px]">arrow_back</span>
        Volver al Mapa de Fincas
      </button>

      {/* ── Banner de Finca ──────────────────────────────── */}
      <div className="rounded-2xl bg-gradient-to-r from-[#012d1d] via-[#0b4d34] to-[#125c40] p-6 text-white shadow-xl relative overflow-hidden">
        <div className="absolute right-0 top-0 w-64 h-64 bg-emerald-400/10 rounded-full blur-3xl pointer-events-none"></div>
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 relative z-10">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="material-symbols-outlined text-emerald-300 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
              <h2 className="text-3xl font-extrabold tracking-tight" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>{detalle.nombre}</h2>
              {detalle.tieneAlertasSanitarias && (
                <span className="ml-2 inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-rose-500/30 border border-rose-400/40 text-rose-200 text-xs font-bold">
                  <span className="w-1.5 h-1.5 rounded-full bg-rose-400 animate-pulse"></span>
                  Alerta Activa
                </span>
              )}
            </div>
            <p className="text-emerald-100/80 text-sm">
              <span className="font-bold">{detalle.ganaderoNombre}</span>
              {' · '}{detalle.municipio}{detalle.comarca ? ` · ${detalle.comarca}` : ''}
              {' · '}<span className="font-mono">{detalle.ganaderoTelefono}</span>
            </p>
            {detalle.latitud !== 0 && (
              <a href={`https://www.google.com/maps?q=${detalle.latitud},${detalle.longitud}`}
                target="_blank" rel="noopener noreferrer"
                className="inline-flex items-center gap-1 text-xs text-emerald-300 hover:text-white mt-1.5">
                <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>location_on</span>
                {detalle.latitud?.toFixed(4)}, {detalle.longitud?.toFixed(4)}
              </a>
            )}
          </div>
        </div>
      </div>

      {/* ── KPIs ─────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total Animales', value: detalle.totalAnimales, sub: `${detalle.totalHembras}♀ / ${detalle.totalMachos}♂`, icon: 'pets', color: 'emerald' },
          { label: 'Producción Hoy', value: `${detalle.produccionHoyLitros} L`, sub: `${detalle.produccionHoyKg} kg`, icon: 'water_drop', color: 'blue' },
          { label: 'UGM Totales', value: detalle.totalUGM, sub: 'Unidades Ganaderas', icon: 'scale', color: 'teal' },
          { label: 'Enfermos', value: detalle.animalesEnfermos, sub: detalle.animalesEnfermos > 0 ? 'Requieren atención' : 'Sin novedades', icon: 'vaccines', color: detalle.animalesEnfermos > 0 ? 'rose' : 'slate' },
        ].map((kpi, i) => (
          <div key={i} className={`bg-white rounded-2xl p-4 shadow-sm border border-${kpi.color}-100 flex flex-col items-start card-hover-effect animate-slide-up`} style={{ animationDelay: `${i * 75}ms` }}>
            <div className={`w-10 h-10 rounded-xl bg-${kpi.color}-100 flex items-center justify-center mb-3`}>
              <span className={`material-symbols-outlined text-${kpi.color}-600 text-xl`} style={{ fontVariationSettings: "'FILL' 1" }}>{kpi.icon}</span>
            </div>
            <p className={`text-2xl font-black text-${kpi.color}-900`}>{kpi.value}</p>
            <p className={`text-xs font-bold text-${kpi.color}-600 uppercase tracking-wide`}>{kpi.label}</p>
            <p className="text-xs text-slate-400 mt-0.5">{kpi.sub}</p>
          </div>
        ))}
      </div>

      {/* ── Tabs ─────────────────────────────────────────── */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="flex border-b border-slate-200">
          {([['animales', 'pets', 'Animales'], ['salud', 'medical_services', 'Historial de Salud'], ['produccion', 'show_chart', 'Producción 30 días']] as const).map(([key, icon, label]) => (
            <button
              key={key}
              onClick={() => setTab(key)}
              className={`flex items-center gap-2 px-5 py-3.5 text-sm font-semibold transition-all border-b-2 ${
                tab === key
                  ? 'border-emerald-500 text-emerald-700 bg-emerald-50/60'
                  : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50'
              }`}
            >
              <span className="material-symbols-outlined text-[18px]" style={{ fontVariationSettings: tab === key ? "'FILL' 1" : "" }}>{icon}</span>
              {label}
            </button>
          ))}
        </div>

        {/* Tab: Animales */}
        {tab === 'animales' && (
          <div>
            <div className="p-4 border-b border-slate-100">
              <div className="relative w-64">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-lg">search</span>
                <input
                  type="text"
                  placeholder="Buscar por arete o raza..."
                  value={searchAnimal}
                  onChange={e => setSearchAnimal(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                />
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
                    <th className="py-2.5 px-4">Identificación</th>
                    <th className="py-2.5 px-4 text-center">Sexo</th>
                    <th className="py-2.5 px-4">Raza</th>
                    <th className="py-2.5 px-4 text-center">Edad</th>
                    <th className="py-2.5 px-4 text-center">UGM</th>
                    <th className="py-2.5 px-4 text-center">Estado</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredAnimales.length === 0 ? (
                    <tr><td colSpan={6} className="py-10 text-center text-slate-400 italic text-sm">Sin animales registrados.</td></tr>
                  ) : filteredAnimales.map((a: any) => (
                    <tr key={a.id} className="hover:bg-emerald-50/40 transition-colors">
                      <td className="py-3 px-4 font-bold text-slate-900 font-mono">{a.identificacion}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-bold ${a.sexo === 'Hembra' ? 'bg-pink-100 text-pink-700' : 'bg-blue-100 text-blue-700'}`}>
                          {a.sexo === 'Hembra' ? '♀' : '♂'} {a.sexo}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-slate-700">{a.raza}</td>
                      <td className="py-3 px-4 text-center text-slate-600 tabular-nums">
                        {a.edadMeses >= 12 ? `${Math.floor(a.edadMeses / 12)} a ${a.edadMeses % 12} m` : `${a.edadMeses} meses`}
                      </td>
                      <td className="py-3 px-4 text-center font-bold text-teal-700 tabular-nums">{a.ugm}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${ESTADO_STYLES[a.estado] ?? 'bg-slate-100 text-slate-600'}`}>{a.estado}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Tab: Historial Salud */}
        {tab === 'salud' && (
          <div className="overflow-x-auto">
            <table className="w-full text-sm border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
                  <th className="py-2.5 px-4">Fecha</th>
                  <th className="py-2.5 px-4">Animal</th>
                  <th className="py-2.5 px-4">Diagnóstico</th>
                  <th className="py-2.5 px-4">Medicamentos</th>
                  <th className="py-2.5 px-4">Observaciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {(!detalle.ultimosSalud || detalle.ultimosSalud.length === 0) ? (
                  <tr><td colSpan={5} className="py-10 text-center text-slate-400 italic text-sm">Sin registros de salud.</td></tr>
                ) : detalle.ultimosSalud.map((rs: any) => (
                  <tr key={rs.id} className="hover:bg-rose-50/40 transition-colors">
                    <td className="py-3 px-4 text-slate-600 text-xs font-mono whitespace-nowrap">{new Date(rs.fechaDeteccion).toLocaleDateString('es-NI')}</td>
                    <td className="py-3 px-4 font-bold text-slate-900 font-mono">{rs.animalIdentificacion}</td>
                    <td className="py-3 px-4">
                      <span className="px-2.5 py-1 rounded-full bg-rose-100 text-rose-700 font-bold text-xs">{rs.enfermedad}</span>
                    </td>
                    <td className="py-3 px-4 text-slate-600 text-xs">{rs.medicamentos.join(', ') || '—'}</td>
                    <td className="py-3 px-4 text-slate-500 text-xs max-w-xs truncate">{rs.observaciones || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab: Producción 30 días */}
        {tab === 'produccion' && (
          <div className="p-5">
            <p className="text-xs text-slate-500 mb-4">Producción diaria de leche en los últimos 30 días (litros).</p>
            <div className="space-y-2">
              {(detalle.tendencia30Dias || []).map((item: any, idx: number) => {
                const pct = Math.min(100, Math.round((item.litros / maxBar) * 100));
                return (
                  <div key={idx} className="flex items-center gap-3 text-xs">
                    <span className="w-10 text-slate-500 font-bold shrink-0 tabular-nums">{item.fecha}</span>
                    <div className="flex-1 bg-slate-100 h-5 rounded-full overflow-hidden">
                      <div className="bg-gradient-to-r from-emerald-500 to-teal-600 h-full rounded-full transition-all duration-500"
                        style={{ width: `${pct}%` }}></div>
                    </div>
                    <span className="w-20 text-right font-black text-slate-700 tabular-nums shrink-0">
                      {item.litros > 0 ? `${item.litros}L` : <span className="text-slate-300">—</span>}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default FarmDetail;
