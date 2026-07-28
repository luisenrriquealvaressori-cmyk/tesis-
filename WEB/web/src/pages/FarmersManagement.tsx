import { useEffect, useState } from 'react';
import { fetchGanaderos, resetClaveAppApi } from '../services/api';
import { useExport, GANADERO_EXPORT_COLUMNS } from '../hooks/useExport';
import { useAuth } from '../context/AuthContext';


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

const strengthLabel = (len: number) => {
  if (len < 6) return 'Muy corta';
  if (len < 8) return 'Débil';
  if (len < 12) return 'Moderada';
  return '✓ Fuerte';
};

const RowSkeleton = ({ isAdmin }: { isAdmin: boolean }) => (
  <tr>
    {(isAdmin ? [60, 40, 50, 30, 30, 30, 10] : [60, 40, 50, 30, 30, 30]).map((w, i) => (
      <td key={i} className="py-3 px-4">
        <div className={`skeleton h-3.5 rounded`} style={{ width: `${w}%` }}></div>
      </td>
    ))}
  </tr>
);

const FarmersManagement = () => {
  const { rol } = useAuth();
  const isAdmin = rol === 'Administrador';

  const [ganaderos, setGanaderos] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const { exportToCSV, exporting } = useExport();

  // Reset password modal
  const [resetTarget, setResetTarget] = useState<any | null>(null);
  const [resetClave, setResetClave] = useState('');
  const [resetConfirm, setResetConfirm] = useState('');
  const [resetError, setResetError] = useState('');
  const [resetting, setResetting] = useState(false);
  const [resetSuccess, setResetSuccess] = useState('');

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

  const handleSearch = (v: string) => {
    setSearchTerm(v);
    setPage(1);
  };

  const handleExport = () => {
    exportToCSV(filtered, GANADERO_EXPORT_COLUMNS, 'Padron_Ganaderos.csv');
  };

  const openReset = (g: any) => {
    setResetTarget(g);
    setResetClave('');
    setResetConfirm('');
    setResetError('');
    setResetSuccess('');
  };

  const handleResetClaveApp = async () => {
    if (!resetClave || resetClave.length < 6) {
      setResetError('La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (resetClave !== resetConfirm) {
      setResetError('Las contraseñas no coinciden.');
      return;
    }
    setResetting(true);
    setResetError('');
    try {
      const res = await resetClaveAppApi(resetTarget.id, resetClave);
      setResetSuccess(res.message || 'Contraseña restablecida correctamente.');
      setResetClave('');
      setResetConfirm('');
      setTimeout(() => { setResetTarget(null); setResetSuccess(''); }, 2200);
    } catch (e: any) {
      setResetError(e.message || 'Error al restablecer la contraseña.');
    } finally {
      setResetting(false);
    }
  };

  return (
    <div className="flex flex-col gap-5 animate-fade-in">
      {/* ── Header ───────────────────────────────────────── */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
            <span className="material-symbols-outlined text-emerald-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>groups</span>
            Padrón de Ganaderos
          </h2>
          <p className="text-slate-500 text-sm mt-0.5">
            {loading ? 'Cargando padrón...' : `${ganaderos.length} productor${ganaderos.length !== 1 ? 'es' : ''} registrado${ganaderos.length !== 1 ? 's' : ''}`}
          </p>
        </div>
        
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-72">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-[20px]">search</span>
            <input
              type="text"
              placeholder="Buscar por nombre, municipio..."
              value={searchTerm}
              onChange={(e) => handleSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
            />
          </div>
          <button
            onClick={handleExport}
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
                {isAdmin && <th className="py-3 px-4 text-center">Acciones</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                [1,2,3,4,5].map(i => <RowSkeleton key={i} isAdmin={isAdmin} />)
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan={isAdmin ? 7 : 6} className="py-14 text-center">
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
                    {isAdmin && (
                      <td className="py-3.5 px-4 text-center">
                        <button
                          onClick={() => openReset(g)}
                          title="Restablecer contraseña móvil"
                          className="p-2 rounded-xl text-slate-400 hover:bg-amber-100 hover:text-amber-600 transition-colors"
                        >
                          <span className="material-symbols-outlined text-[18px]">key</span>
                        </button>
                      </td>
                    )}
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

      {/* ── Modal: Restablecer contraseña ─────────────────── */}
      {resetTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm animate-fade-in">
          <div className="bg-white rounded-2xl shadow-2xl border border-slate-200 p-6 w-full max-w-sm mx-4 animate-scale-in">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg font-extrabold text-slate-900" style={{ fontFamily: 'Outfit, sans-serif' }}>
                  Restablecer Contraseña Móvil
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Ganadero: <span className="font-bold text-slate-700">{resetTarget.nombre}</span>
                </p>
              </div>
              <button
                onClick={() => setResetTarget(null)}
                className="p-1.5 rounded-lg hover:bg-slate-100 text-slate-500"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            {resetSuccess ? (
              <div className="py-8 flex flex-col items-center gap-3 text-center">
                <span
                  className="material-symbols-outlined text-emerald-500 text-5xl"
                  style={{ fontVariationSettings: "'FILL' 1" }}
                >
                  check_circle
                </span>
                <p className="font-bold text-emerald-700">{resetSuccess}</p>
              </div>
            ) : (
              <>
                {resetError && (
                  <div className="mb-4 p-3 rounded-xl bg-rose-50 text-rose-700 text-sm flex items-center gap-2 border border-rose-200">
                    <span className="material-symbols-outlined text-[16px]">error</span>
                    {resetError}
                  </div>
                )}
                <div className="space-y-3">
                  <div>
                    <label className="block text-xs font-semibold text-slate-600 mb-1">Nueva Contraseña</label>
                    <input
                      type="password"
                      placeholder="Mínimo 6 caracteres"
                      value={resetClave}
                      onChange={e => setResetClave(e.target.value)}
                      className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-slate-600 mb-1">Confirmar Contraseña</label>
                    <input
                      type="password"
                      placeholder="Repite la contraseña"
                      value={resetConfirm}
                      onChange={e => setResetConfirm(e.target.value)}
                      className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500"
                    />
                  </div>

                  {resetClave.length > 0 && (
                    <div className="space-y-1">
                      <div className="flex gap-1">
                        {[6, 8, 12].map((len, i) => (
                          <div
                            key={i}
                            className={`h-1.5 flex-1 rounded-full transition-all ${
                              resetClave.length >= len
                                ? i === 0 ? 'bg-rose-400' : i === 1 ? 'bg-amber-400' : 'bg-emerald-500'
                                : 'bg-slate-200'
                            }`}
                          />
                        ))}
                      </div>
                      <p className="text-[10px] text-slate-400">{strengthLabel(resetClave.length)}</p>
                    </div>
                  )}
                </div>

                <div className="flex gap-3 mt-5">
                  <button
                    onClick={() => setResetTarget(null)}
                    className="flex-1 py-2.5 rounded-xl border border-slate-200 text-slate-600 font-semibold text-sm hover:bg-slate-50 transition-colors"
                  >
                    Cancelar
                  </button>
                  <button
                    onClick={handleResetClaveApp}
                    disabled={resetting}
                    className="flex-1 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm transition-all disabled:opacity-50 flex items-center justify-center gap-2"
                  >
                    {resetting ? (
                      <>
                        <span className="material-symbols-outlined animate-spin text-[16px]">sync</span>
                        Guardando...
                      </>
                    ) : (
                      <>
                        <span className="material-symbols-outlined text-[16px]">key</span>
                        Restablecer
                      </>
                    )}
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default FarmersManagement;
