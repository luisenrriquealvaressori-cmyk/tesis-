import { useEffect, useState } from 'react';
import { fetchGanaderos } from '../services/api';
import { useExport, GANADERO_EXPORT_COLUMNS } from '../hooks/useExport';


const ROWS_PER_PAGE = 10;

// Avatar color determinístico por hash
const getAvatarColor = (name: string): string => {
  const colors = [
    ['bg-emerald-100 text-emerald-800', 'bg-emerald-500'],
    ['bg-teal-100 text-teal-800', 'bg-teal-500'],
    ['bg-blue-100 text-blue-800', 'bg-blue-500'],
    ['bg-violet-100 text-violet-800', 'bg-violet-500'],
    ['bg-amber-100 text-amber-800', 'bg-amber-500'],
    ['bg-rose-100 text-rose-800', 'bg-rose-500'],
    ['bg-cyan-100 text-cyan-800', 'bg-cyan-500'],
    ['bg-indigo-100 text-indigo-800', 'bg-indigo-500'],
  ];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash += name.charCodeAt(i);
  return colors[hash % colors.length][0];
};

const RowSkeleton = () => (
  <tr>
    {[60, 40, 50, 30, 30, 30].map((w, i) => (
      <td key={i} className="py-3 px-4">
        <div className={`skeleton h-3.5 rounded`} style={{ width: `${w}%` }}></div>
      </td>
    ))}
  </tr>
);

const FarmersManagement = () => {
  const [ganaderos, setGanaderos] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const { exportToCSV, exporting } = useExport();

  useEffect(() => {
    const load = async () => {
      try {
        const data = await fetchGanaderos();
        setGanaderos(data);
      } catch (error) {
        console.error('Failed to load ganaderos', error);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const filtered = ganaderos.filter(g =>
    g.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
    g.telefono?.includes(searchTerm) ||
    g.municipio?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalPages = Math.ceil(filtered.length / ROWS_PER_PAGE);
  const paginated = filtered.slice((page - 1) * ROWS_PER_PAGE, page * ROWS_PER_PAGE);

  const handleSearch = (val: string) => {
    setSearchTerm(val);
    setPage(1);
  };


  return (
    <div className="flex flex-col gap-6 animate-fade-in">

      {/* ── Header Bar ───────────────────────────────────── */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
            <span className="material-symbols-outlined text-emerald-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>groups</span>
            Padrón Institucional de Ganaderos
          </h2>
          <p className="text-slate-500 text-sm mt-1">
            {loading ? 'Cargando padrón...' : `${filtered.length} ganadero${filtered.length !== 1 ? 's' : ''} registrado${filtered.length !== 1 ? 's' : ''}`}
          </p>
        </div>
        <div className="flex items-center gap-3 flex-wrap">
          {/* Search */}
          <div className="relative w-full md:w-64">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-xl">search</span>
            <input
              type="text"
              placeholder="Buscar por nombre, teléfono..."
              value={searchTerm}
              onChange={(e) => handleSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
            />
          </div>
          {/* Export CSV */}
          <button
            onClick={() => exportToCSV(filtered, GANADERO_EXPORT_COLUMNS, 'padron_ganaderos')}
            disabled={loading || exporting || filtered.length === 0}
            className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-semibold transition-all hover:scale-[1.02] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed shadow-sm"
          >
            <span className="material-symbols-outlined text-[18px]">{exporting ? 'sync' : 'download'}</span>
            {exporting ? 'Exportando...' : `Exportar CSV (${filtered.length})`}
          </button>
        </div>
      </div>

      {/* ── Tabla ────────────────────────────────────────── */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
                <th className="py-3 px-4">Ganadero</th>
                <th className="py-3 px-4">Teléfono</th>
                <th className="py-3 px-4">Municipio / Comarca</th>
                <th className="py-3 px-4 text-center">Fincas</th>
                <th className="py-3 px-4 text-center">Ganado</th>
                <th className="py-3 px-4 text-center">Fecha Registro</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                [1,2,3,4,5].map(i => <RowSkeleton key={i} />)
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-14 text-center">
                    <span className="material-symbols-outlined text-slate-300 text-5xl block mb-2">person_search</span>
                    <p className="text-slate-400 italic text-sm">No se encontraron ganaderos que coincidan.</p>
                    {searchTerm && (
                      <button onClick={() => handleSearch('')} className="mt-2 text-emerald-600 text-xs hover:underline">
                        Limpiar búsqueda
                      </button>
                    )}
                  </td>
                </tr>
              ) : (
                paginated.map((g) => (
                  <tr key={g.id} className="hover:bg-emerald-50/40 transition-colors group">
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-full ${getAvatarColor(g.nombre)} font-bold flex items-center justify-center text-sm shrink-0 group-hover:scale-110 transition-transform`}>
                          {g.nombre.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <p className="font-bold text-slate-900">{g.nombre}</p>
                          <p className="text-xs text-slate-400 font-mono">{g.id?.substring(0, 8)}…</p>
                        </div>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 text-slate-700 font-semibold tabular-nums">{g.telefono || '—'}</td>
                    <td className="py-3.5 px-4 text-slate-600">
                      {g.municipio}{g.comarca ? <span className="text-slate-400"> · {g.comarca}</span> : ''}
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 font-extrabold text-xs">
                        <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
                        {g.totalFincas}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-teal-100 text-teal-800 font-extrabold text-xs">
                        <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>pets</span>
                        {g.totalAnimales}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-center text-slate-500 text-xs font-mono">
                      {new Date(g.createdAt).toLocaleDateString('es-NI')}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* ── Paginación ───────────────────────────────────── */}
        {!loading && totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-100 bg-slate-50">
            <span className="text-xs text-slate-500">
              Mostrando {(page - 1) * ROWS_PER_PAGE + 1}–{Math.min(page * ROWS_PER_PAGE, filtered.length)} de {filtered.length}
            </span>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1.5 rounded-lg text-slate-600 hover:bg-slate-200 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <span className="material-symbols-outlined text-[18px]">chevron_left</span>
              </button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
                <button
                  key={p}
                  onClick={() => setPage(p)}
                  className={`w-8 h-8 rounded-lg text-xs font-bold transition-all ${
                    p === page
                      ? 'bg-emerald-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {p}
                </button>
              ))}
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg text-slate-600 hover:bg-slate-200 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <span className="material-symbols-outlined text-[18px]">chevron_right</span>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default FarmersManagement;
