import { useEffect, useState } from 'react';
import { fetchAnimalesGlobal } from '../services/api';
import { useNavigate } from 'react-router-dom';

const ESTADO_STYLES: Record<string, string> = {
  Sana: 'bg-emerald-100 text-emerald-800',
  Enferma: 'bg-rose-100 text-rose-700',
  'En Tratamiento': 'bg-amber-100 text-amber-700',
};

const ROWS_PER_PAGE = 15;

const RowSkeleton = () => (
  <tr>{[60,30,30,30,25,25,25].map((w,i) => (
    <td key={i} className="py-3 px-4"><div className="skeleton h-3.5 rounded" style={{ width: `${w}%` }}></div></td>
  ))}</tr>
);

const AnimalesPanel = () => {
  const [animales, setAnimales] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterSexo, setFilterSexo] = useState<'All' | 'Hembra' | 'Macho'>('All');
  const [filterEstado, setFilterEstado] = useState<'All' | 'Sana' | 'Enferma' | 'En Tratamiento'>('All');
  const [page, setPage] = useState(1);
  const navigate = useNavigate();

  useEffect(() => {
    const load = async () => {
      try {
        const data = await fetchAnimalesGlobal();
        setAnimales(data);
      } catch (e) { console.error(e); }
      finally { setLoading(false); }
    };
    load();
  }, []);

  const filtered = animales.filter(a => {
    if (filterSexo !== 'All' && a.sexo !== filterSexo) return false;
    if (filterEstado !== 'All' && a.estado !== filterEstado) return false;
    if (search) {
      const s = search.toLowerCase();
      return a.identificacion.toLowerCase().includes(s) ||
             a.finca.toLowerCase().includes(s) ||
             a.ganadero.toLowerCase().includes(s) ||
             a.raza.toLowerCase().includes(s);
    }
    return true;
  });

  const totalPages = Math.ceil(filtered.length / ROWS_PER_PAGE);
  const paginated = filtered.slice((page - 1) * ROWS_PER_PAGE, page * ROWS_PER_PAGE);

  const stats = {
    total: animales.length,
    hembras: animales.filter(a => a.sexo === 'Hembra').length,
    machos: animales.filter(a => a.sexo === 'Macho').length,
    enfermos: animales.filter(a => a.estado !== 'Sana').length,
  };

  return (
    <div className="flex flex-col gap-5 animate-fade-in">

      {/* ── Header ──────────────────────────────────────── */}
      <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
              <span className="material-symbols-outlined text-teal-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>pets</span>
              Panel de Animales
            </h2>
            <p className="text-slate-500 text-sm mt-0.5">
              Inventario completo de todas las fincas registradas en el sistema.
            </p>
          </div>
          <div className="flex items-center gap-3 flex-wrap">
            {[
              { label: 'Total', value: stats.total, color: 'slate' },
              { label: '♀ Hembras', value: stats.hembras, color: 'pink' },
              { label: '♂ Machos', value: stats.machos, color: 'blue' },
              { label: '⚠ Enfermos', value: stats.enfermos, color: 'rose' },
            ].map(s => (
              <div key={s.label} className={`text-center px-3 py-1.5 rounded-xl bg-${s.color}-50 border border-${s.color}-100`}>
                <p className={`text-lg font-black text-${s.color}-700`}>{loading ? '—' : s.value}</p>
                <p className={`text-[10px] font-bold text-${s.color}-500 uppercase tracking-wide`}>{s.label}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Filters */}
        <div className="mt-4 pt-4 border-t border-slate-100 flex flex-wrap gap-3 items-center">
          <div className="relative w-72">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-lg">search</span>
            <input
              type="text" placeholder="Buscar arete, finca, ganadero..."
              value={search} onChange={e => { setSearch(e.target.value); setPage(1); }}
              className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500"
            />
          </div>
          <div className="flex gap-2">
            <span className="text-xs font-semibold text-slate-400 self-center">Sexo:</span>
            {(['All', 'Hembra', 'Macho'] as const).map(s => (
              <button key={s} onClick={() => { setFilterSexo(s); setPage(1); }}
                className={`px-3 py-1 rounded-full text-xs font-bold border transition-all ${filterSexo === s ? 'bg-teal-600 text-white border-teal-600' : 'bg-white text-slate-500 border-slate-200 hover:border-teal-400'}`}>
                {s === 'All' ? 'Todos' : s === 'Hembra' ? '♀ Hembras' : '♂ Machos'}
              </button>
            ))}
          </div>
          <div className="flex gap-2">
            <span className="text-xs font-semibold text-slate-400 self-center">Estado:</span>
            {(['All', 'Sana', 'Enferma', 'En Tratamiento'] as const).map(s => (
              <button key={s} onClick={() => { setFilterEstado(s); setPage(1); }}
                className={`px-3 py-1 rounded-full text-xs font-bold border transition-all ${filterEstado === s ? 'bg-slate-700 text-white border-slate-700' : 'bg-white text-slate-500 border-slate-200 hover:border-slate-400'}`}>
                {s === 'All' ? 'Todos' : s}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── Tabla ────────────────────────────────────────── */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
                <th className="py-2.5 px-4">Identificación</th>
                <th className="py-2.5 px-4">Finca</th>
                <th className="py-2.5 px-4">Ganadero</th>
                <th className="py-2.5 px-4">Raza</th>
                <th className="py-2.5 px-4 text-center">Sexo</th>
                <th className="py-2.5 px-4 text-center">Edad</th>
                <th className="py-2.5 px-4 text-center">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                [1,2,3,4,5].map(i => <RowSkeleton key={i} />)
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-14 text-center">
                    <span className="material-symbols-outlined text-slate-300 text-5xl block mb-2">pets</span>
                    <p className="text-slate-400 italic text-sm">No se encontraron animales con los filtros aplicados.</p>
                  </td>
                </tr>
              ) : paginated.map((a: any) => (
                <tr key={a.id} className="hover:bg-teal-50/40 transition-colors group">
                  <td className="py-3 px-4 font-bold text-slate-900 font-mono">{a.identificacion}</td>
                  <td className="py-3 px-4">
                    <button
                      onClick={() => navigate(`/farms/${a.fincaId}`)}
                      className="flex items-center gap-1.5 text-emerald-700 font-semibold hover:underline"
                    >
                      <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
                      {a.finca}
                    </button>
                  </td>
                  <td className="py-3 px-4 text-slate-600">{a.ganadero}</td>
                  <td className="py-3 px-4 text-slate-700">{a.raza}</td>
                  <td className="py-3 px-4 text-center">
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-bold ${a.sexo === 'Hembra' ? 'bg-pink-100 text-pink-700' : 'bg-blue-100 text-blue-700'}`}>
                      {a.sexo === 'Hembra' ? '♀' : '♂'} {a.sexo}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-center text-slate-600 tabular-nums text-xs">
                    {a.edadMeses >= 12 ? `${Math.floor(a.edadMeses / 12)}a ${a.edadMeses % 12}m` : `${a.edadMeses}m`}
                  </td>
                  <td className="py-3 px-4 text-center">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${ESTADO_STYLES[a.estado] ?? 'bg-slate-100 text-slate-600'}`}>{a.estado}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Paginación */}
        {!loading && totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-100 bg-slate-50">
            <span className="text-xs text-slate-500">
              {(page-1)*ROWS_PER_PAGE+1}–{Math.min(page*ROWS_PER_PAGE, filtered.length)} de {filtered.length}
            </span>
            <div className="flex items-center gap-1">
              <button onClick={() => setPage(p => Math.max(1, p-1))} disabled={page===1}
                className="p-1.5 rounded-lg text-slate-600 hover:bg-slate-200 disabled:opacity-30 disabled:cursor-not-allowed">
                <span className="material-symbols-outlined text-[18px]">chevron_left</span>
              </button>
              {Array.from({length: Math.min(totalPages, 7)}, (_, i) => i+1).map(p => (
                <button key={p} onClick={() => setPage(p)}
                  className={`w-8 h-8 rounded-lg text-xs font-bold transition-all ${p===page ? 'bg-teal-600 text-white' : 'text-slate-600 hover:bg-slate-200'}`}>{p}</button>
              ))}
              <button onClick={() => setPage(p => Math.min(totalPages, p+1))} disabled={page===totalPages}
                className="p-1.5 rounded-lg text-slate-600 hover:bg-slate-200 disabled:opacity-30 disabled:cursor-not-allowed">
                <span className="material-symbols-outlined text-[18px]">chevron_right</span>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default AnimalesPanel;
