import { useEffect, useState } from 'react';
import { fetchAnimalesGlobal } from '../services/api';
import AnimalDrawer from '../components/AnimalDrawer';
import { useExport, ANIMAL_EXPORT_COLUMNS } from '../hooks/useExport';

// ── Tipos ────────────────────────────────────────────────────────────────────
type Sexo = 'All' | 'Hembra' | 'Macho';
type Estado = 'All' | 'Sana' | 'Enferma' | 'En Tratamiento';
type Categoria = 'All' | 'Adulto' | 'Joven' | 'Cría';

const ESTADO_STYLES: Record<string, string> = {
  Sana: 'bg-emerald-100 text-emerald-800',
  Enferma: 'bg-rose-100 text-rose-700',
  'En Tratamiento': 'bg-amber-100 text-amber-700',
};

const SEMAFORO: Record<string, string> = {
  Sana: 'bg-emerald-400',
  Enferma: 'bg-rose-500',
  'En Tratamiento': 'bg-amber-400',
};

const ROWS_PER_PAGE = 15;

const RowSkeleton = () => (
  <tr>{[60,30,30,30,25,25,25].map((w,i) => (
    <td key={i} className="py-3 px-4"><div className="skeleton h-3.5 rounded" style={{ width: `${w}%` }}></div></td>
  ))}</tr>
);

// ── Botón de exportar reutilizable ─────────────────────────────────────────
const ExportButton = ({ onClick, loading, count }: { onClick: () => void; loading: boolean; count: number }) => (
  <button
    onClick={onClick}
    disabled={loading || count === 0}
    className="flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 bg-white text-slate-600 text-xs font-semibold hover:bg-emerald-50 hover:border-emerald-300 hover:text-emerald-700 transition-all disabled:opacity-40 disabled:cursor-not-allowed"
    title={`Exportar ${count} registros a CSV`}
  >
    {loading ? (
      <span className="material-symbols-outlined text-[16px] animate-spin">sync</span>
    ) : (
      <span className="material-symbols-outlined text-[16px]">download</span>
    )}
    {loading ? 'Exportando...' : `Exportar CSV (${count})`}
  </button>
);

// ── Componente principal ───────────────────────────────────────────────────
const AnimalesPanel = () => {
  const [animales, setAnimales] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Filtros básicos
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);

  // Filtros avanzados (off-canvas)
  const [showAdvFilter, setShowAdvFilter] = useState(false);
  const [filterSexo, setFilterSexo] = useState<Sexo>('All');
  const [filterEstado, setFilterEstado] = useState<Estado>('All');
  const [filterCategoria, setFilterCategoria] = useState<Categoria>('All');
  const [filterFinca, setFilterFinca] = useState('');
  const [filterEdadMin, setFilterEdadMin] = useState('');
  const [filterEdadMax, setFilterEdadMax] = useState('');

  // Drawer de detalle
  const [selectedAnimal, setSelectedAnimal] = useState<any | null>(null);

  const { exportToCSV, exporting } = useExport();

  useEffect(() => {
    fetchAnimalesGlobal()
      .then(setAnimales)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  // Listas únicas para filtros
  const fincas = [...new Set(animales.map(a => a.finca))].sort();


  const getCategoria = (meses: number) =>
    meses >= 24 ? 'Adulto' : meses >= 12 ? 'Joven' : 'Cría';

  const filteredAll = animales.filter(a => {
    if (filterSexo !== 'All' && a.sexo !== filterSexo) return false;
    if (filterEstado !== 'All' && a.estado !== filterEstado) return false;
    if (filterCategoria !== 'All' && getCategoria(a.edadMeses) !== filterCategoria) return false;
    if (filterFinca && a.finca !== filterFinca) return false;
    if (filterEdadMin && a.edadMeses < parseInt(filterEdadMin)) return false;
    if (filterEdadMax && a.edadMeses > parseInt(filterEdadMax)) return false;
    if (search) {
      const s = search.toLowerCase();
      return (
        a.identificacion.toLowerCase().includes(s) ||
        a.finca.toLowerCase().includes(s) ||
        a.ganadero.toLowerCase().includes(s) ||
        a.raza.toLowerCase().includes(s)
      );
    }
    return true;
  });

  const activeFilters = [
    filterSexo !== 'All', filterEstado !== 'All', filterCategoria !== 'All',
    !!filterFinca, !!filterEdadMin, !!filterEdadMax
  ].filter(Boolean).length;

  const totalPages = Math.ceil(filteredAll.length / ROWS_PER_PAGE);
  const paginated = filteredAll.slice((page - 1) * ROWS_PER_PAGE, page * ROWS_PER_PAGE);

  const resetFilters = () => {
    setFilterSexo('All'); setFilterEstado('All'); setFilterCategoria('All');
    setFilterFinca(''); setFilterEdadMin(''); setFilterEdadMax('');
    setPage(1);
  };

  const stats = {
    total: animales.length,
    hembras: animales.filter(a => a.sexo === 'Hembra').length,
    machos: animales.filter(a => a.sexo === 'Macho').length,
    enfermos: animales.filter(a => a.estado !== 'Sana').length,
  };

  return (
    <div className="flex flex-col gap-5 animate-fade-in">

      {/* ── Drawer de detalle ─────────────────────────────── */}
      <AnimalDrawer animal={selectedAnimal} onClose={() => setSelectedAnimal(null)} />

      {/* ── Panel de Filtros Avanzados (off-canvas) ────────── */}
      {showAdvFilter && (
        <>
          <div className="fixed inset-0 bg-black/20 backdrop-blur-[1px] z-30 animate-fade-in" onClick={() => setShowAdvFilter(false)} />
          <div className="fixed right-0 top-0 h-full w-80 bg-white shadow-2xl z-40 flex flex-col animate-slide-in-right">
            <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <div>
                <h3 className="font-extrabold text-slate-900 text-base" style={{ fontFamily: 'Outfit, sans-serif' }}>Filtros Avanzados</h3>
                <p className="text-xs text-slate-400">{filteredAll.length} resultado{filteredAll.length !== 1 ? 's' : ''}</p>
              </div>
              <button onClick={() => setShowAdvFilter(false)} className="p-1.5 rounded-lg hover:bg-slate-200 text-slate-500">
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            <div className="flex-1 overflow-y-auto custom-scrollbar px-5 py-4 space-y-5">

              {/* Sexo */}
              <div>
                <label className="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-2">Sexo</label>
                <div className="flex gap-2 flex-wrap">
                  {(['All', 'Hembra', 'Macho'] as Sexo[]).map(s => (
                    <button key={s} onClick={() => { setFilterSexo(s); setPage(1); }}
                      className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${filterSexo === s ? 'bg-teal-600 text-white border-teal-600' : 'bg-white text-slate-500 border-slate-200 hover:border-teal-300'}`}>
                      {s === 'All' ? 'Todos' : s === 'Hembra' ? '♀ Hembras' : '♂ Machos'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Estado */}
              <div>
                <label className="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-2">Estado de Salud</label>
                <div className="flex flex-wrap gap-2">
                  {(['All', 'Sana', 'Enferma', 'En Tratamiento'] as Estado[]).map(s => (
                    <button key={s} onClick={() => { setFilterEstado(s); setPage(1); }}
                      className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${filterEstado === s ? 'bg-slate-800 text-white border-slate-800' : 'bg-white text-slate-500 border-slate-200 hover:border-slate-400'}`}>
                      {s === 'All' ? 'Todos' : s}
                    </button>
                  ))}
                </div>
              </div>

              {/* Categoría por edad */}
              <div>
                <label className="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-2">Categoría de Edad</label>
                <div className="flex flex-wrap gap-2">
                  {(['All', 'Adulto', 'Joven', 'Cría'] as Categoria[]).map(c => (
                    <button key={c} onClick={() => { setFilterCategoria(c); setPage(1); }}
                      className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${filterCategoria === c ? 'bg-violet-600 text-white border-violet-600' : 'bg-white text-slate-500 border-slate-200 hover:border-violet-300'}`}>
                      {c === 'All' ? 'Todas' : c}
                    </button>
                  ))}
                </div>
              </div>

              {/* Finca */}
              <div>
                <label className="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-2">Finca</label>
                <select value={filterFinca} onChange={e => { setFilterFinca(e.target.value); setPage(1); }}
                  className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500">
                  <option value="">Todas las fincas</option>
                  {fincas.map(f => <option key={f} value={f}>{f}</option>)}
                </select>
              </div>

              {/* Rango de edad */}
              <div>
                <label className="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-2">Rango de Edad (meses)</label>
                <div className="flex gap-2 items-center">
                  <input type="number" min="0" placeholder="Mín" value={filterEdadMin}
                    onChange={e => { setFilterEdadMin(e.target.value); setPage(1); }}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500"
                  />
                  <span className="text-slate-400 shrink-0">—</span>
                  <input type="number" min="0" placeholder="Máx" value={filterEdadMax}
                    onChange={e => { setFilterEdadMax(e.target.value); setPage(1); }}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500"
                  />
                </div>
                <p className="text-[10px] text-slate-400 mt-1">Adultos ≥24m · Jóvenes 12–23m · Crías &lt;12m</p>
              </div>
            </div>

            <div className="px-5 py-4 border-t border-slate-100 bg-slate-50 flex gap-3">
              <button onClick={resetFilters}
                className="flex-1 py-2.5 rounded-xl border border-slate-200 text-slate-600 text-sm font-semibold hover:bg-white transition-colors">
                Limpiar filtros
              </button>
              <button onClick={() => setShowAdvFilter(false)}
                className="flex-1 py-2.5 rounded-xl bg-teal-600 text-white text-sm font-bold hover:bg-teal-700 transition-colors">
                Aplicar
              </button>
            </div>
          </div>
        </>
      )}

      {/* ── Header con KPIs ──────────────────────────────────── */}
      <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
              <span className="material-symbols-outlined text-teal-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>pets</span>
              Panel de Animales
            </h2>
            <p className="text-slate-500 text-sm mt-0.5">Haz clic en cualquier fila para ver la ficha completa del animal.</p>
          </div>
          <div className="flex items-center gap-3 flex-wrap">
            {[
              { label: 'Total', value: stats.total, color: 'slate' },
              { label: '♀ Hembras', value: stats.hembras, color: 'pink' },
              { label: '♂ Machos', value: stats.machos, color: 'blue' },
              { label: '⚠ Alertas', value: stats.enfermos, color: 'rose' },
            ].map(s => (
              <div key={s.label} className={`text-center px-3 py-1.5 rounded-xl bg-${s.color}-50 border border-${s.color}-100`}>
                <p className={`text-lg font-black text-${s.color}-700`}>{loading ? '—' : s.value}</p>
                <p className={`text-[10px] font-bold text-${s.color}-500 uppercase tracking-wide`}>{s.label}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Barra de búsqueda + acciones */}
        <div className="mt-4 pt-4 border-t border-slate-100 flex flex-wrap gap-2.5 items-center">
          <div className="relative w-72">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-lg">search</span>
            <input
              type="text" placeholder="Buscar arete, finca, ganadero, raza..."
              value={search} onChange={e => { setSearch(e.target.value); setPage(1); }}
              className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500"
            />
          </div>

          {/* Filtros avanzados */}
          <button
            onClick={() => setShowAdvFilter(true)}
            className={`flex items-center gap-2 px-3 py-2 rounded-xl border text-xs font-semibold transition-all ${
              activeFilters > 0
                ? 'bg-teal-600 text-white border-teal-600 hover:bg-teal-700'
                : 'border-slate-200 bg-white text-slate-600 hover:bg-teal-50 hover:border-teal-300 hover:text-teal-700'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">tune</span>
            Filtros Avanzados
            {activeFilters > 0 && (
              <span className="w-5 h-5 rounded-full bg-white text-teal-700 font-black text-[10px] flex items-center justify-center">
                {activeFilters}
              </span>
            )}
          </button>

          {activeFilters > 0 && (
            <button onClick={resetFilters}
              className="flex items-center gap-1 px-3 py-2 rounded-xl border border-rose-200 bg-rose-50 text-rose-600 text-xs font-semibold hover:bg-rose-100 transition-colors">
              <span className="material-symbols-outlined text-[14px]">filter_alt_off</span>
              Limpiar
            </button>
          )}

          <div className="ml-auto">
            <ExportButton
              onClick={() => exportToCSV(filteredAll, ANIMAL_EXPORT_COLUMNS, 'animales_agrocontrol')}
              loading={exporting}
              count={filteredAll.length}
            />
          </div>
        </div>

        {/* Chips de filtros activos */}
        {activeFilters > 0 && (
          <div className="mt-3 flex flex-wrap gap-2">
            {filterSexo !== 'All' && <span className="inline-flex items-center gap-1 px-2 py-1 bg-teal-100 text-teal-800 text-xs font-bold rounded-full">{filterSexo} <button onClick={() => setFilterSexo('All')} className="ml-1 text-teal-500 hover:text-teal-800">×</button></span>}
            {filterEstado !== 'All' && <span className="inline-flex items-center gap-1 px-2 py-1 bg-slate-100 text-slate-700 text-xs font-bold rounded-full">{filterEstado} <button onClick={() => setFilterEstado('All')} className="ml-1 text-slate-400 hover:text-slate-700">×</button></span>}
            {filterCategoria !== 'All' && <span className="inline-flex items-center gap-1 px-2 py-1 bg-violet-100 text-violet-800 text-xs font-bold rounded-full">{filterCategoria} <button onClick={() => setFilterCategoria('All')} className="ml-1 text-violet-400 hover:text-violet-800">×</button></span>}
            {filterFinca && <span className="inline-flex items-center gap-1 px-2 py-1 bg-emerald-100 text-emerald-800 text-xs font-bold rounded-full">📍 {filterFinca} <button onClick={() => setFilterFinca('')} className="ml-1 text-emerald-400 hover:text-emerald-800">×</button></span>}
            {(filterEdadMin || filterEdadMax) && <span className="inline-flex items-center gap-1 px-2 py-1 bg-amber-100 text-amber-800 text-xs font-bold rounded-full">Edad {filterEdadMin || '0'}–{filterEdadMax || '∞'}m <button onClick={() => { setFilterEdadMin(''); setFilterEdadMax(''); }} className="ml-1 text-amber-400 hover:text-amber-800">×</button></span>}
          </div>
        )}
      </div>

      {/* ── Tabla ──────────────────────────────────────────── */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
                <th className="py-2.5 px-4 text-center w-8"></th>
                <th className="py-2.5 px-4">Identificación</th>
                <th className="py-2.5 px-4">Finca</th>
                <th className="py-2.5 px-4">Ganadero</th>
                <th className="py-2.5 px-4">Raza</th>
                <th className="py-2.5 px-4 text-center">Sexo</th>
                <th className="py-2.5 px-4 text-center">Categoría</th>
                <th className="py-2.5 px-4 text-center">Estado</th>
                <th className="py-2.5 px-4 text-center">Detalle</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                [1,2,3,4,5].map(i => <RowSkeleton key={i} />)
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan={9} className="py-14 text-center">
                    <span className="material-symbols-outlined text-slate-300 text-5xl block mb-2">pets</span>
                    <p className="text-slate-400 italic text-sm">No se encontraron animales con los filtros aplicados.</p>
                    {activeFilters > 0 && (
                      <button onClick={resetFilters} className="mt-2 text-xs text-teal-600 font-semibold hover:underline">
                        Limpiar todos los filtros
                      </button>
                    )}
                  </td>
                </tr>
              ) : paginated.map((a: any) => (
                <tr
                  key={a.id}
                  onClick={() => setSelectedAnimal(a)}
                  className="hover:bg-teal-50/60 transition-colors group cursor-pointer"
                >
                  {/* Semáforo */}
                  <td className="py-3 px-4 text-center">
                    <span className={`inline-block w-2.5 h-2.5 rounded-full ${SEMAFORO[a.estado] ?? 'bg-slate-300'}`}></span>
                  </td>
                  <td className="py-3 px-4 font-bold text-slate-900 font-mono group-hover:text-teal-700 transition-colors">{a.identificacion}</td>
                  <td className="py-3 px-4">
                    <div className="flex items-center gap-1.5 text-emerald-700 font-semibold">
                      <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
                      {a.finca}
                    </div>
                  </td>
                  <td className="py-3 px-4 text-slate-600">{a.ganadero}</td>
                  <td className="py-3 px-4 text-slate-700">{a.raza}</td>
                  <td className="py-3 px-4 text-center">
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-bold ${a.sexo === 'Hembra' ? 'bg-pink-100 text-pink-700' : 'bg-blue-100 text-blue-700'}`}>
                      {a.sexo === 'Hembra' ? '♀' : '♂'} {a.sexo}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <span className="text-xs font-semibold text-slate-600">{getCategoria(a.edadMeses)}</span>
                    <span className="text-[10px] text-slate-400 block">{a.edadMeses >= 12 ? `${Math.floor(a.edadMeses/12)}a ${a.edadMeses%12}m` : `${a.edadMeses}m`}</span>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${ESTADO_STYLES[a.estado] ?? 'bg-slate-100 text-slate-600'}`}>{a.estado}</span>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <button
                      onClick={e => { e.stopPropagation(); setSelectedAnimal(a); }}
                      className="p-1.5 rounded-lg text-slate-400 hover:bg-teal-100 hover:text-teal-700 transition-colors"
                      title="Ver ficha completa"
                    >
                      <span className="material-symbols-outlined text-[18px]">open_in_new</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Footer: total + paginación */}
        {!loading && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-100 bg-slate-50">
            <span className="text-xs text-slate-500">
              {filteredAll.length > 0
                ? `${(page-1)*ROWS_PER_PAGE+1}–${Math.min(page*ROWS_PER_PAGE, filteredAll.length)} de ${filteredAll.length} animales`
                : '0 resultados'}
            </span>
            {totalPages > 1 && (
              <div className="flex items-center gap-1">
                <button onClick={() => setPage(p => Math.max(1, p-1))} disabled={page===1}
                  className="p-1.5 rounded-lg text-slate-600 hover:bg-slate-200 disabled:opacity-30 disabled:cursor-not-allowed">
                  <span className="material-symbols-outlined text-[18px]">chevron_left</span>
                </button>
                {Array.from({length: Math.min(totalPages, 7)}, (_,i) => i+1).map(p => (
                  <button key={p} onClick={() => setPage(p)}
                    className={`w-8 h-8 rounded-lg text-xs font-bold transition-all ${p===page ? 'bg-teal-600 text-white' : 'text-slate-600 hover:bg-slate-200'}`}>{p}</button>
                ))}
                <button onClick={() => setPage(p => Math.min(totalPages, p+1))} disabled={page===totalPages}
                  className="p-1.5 rounded-lg text-slate-600 hover:bg-slate-200 disabled:opacity-30 disabled:cursor-not-allowed">
                  <span className="material-symbols-outlined text-[18px]">chevron_right</span>
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default AnimalesPanel;
