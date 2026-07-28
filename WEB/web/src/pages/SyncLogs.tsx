import { useEffect, useState, useCallback } from 'react';
import { fetchAuditoriaSync } from '../services/api';

type ActionType = 'Insert' | 'Update' | 'Delete' | 'All';

const ACTION_STYLES: Record<string, string> = {
  Insert: 'bg-emerald-100 text-emerald-800 border border-emerald-200',
  Update: 'bg-blue-100 text-blue-800 border border-blue-200',
  Delete: 'bg-rose-100 text-rose-700 border border-rose-200',
};
const ACTION_ICONS: Record<string, string> = {
  Insert: 'add_circle',
  Update: 'edit',
  Delete: 'delete',
};

const RowSkeleton = () => (
  <tr>
    {[40, 30, 30, 25, 20, 30].map((w, i) => (
      <td key={i} className="py-3 px-4">
        <div className="skeleton h-3.5 rounded" style={{ width: `${w + Math.random() * 20}%` }}></div>
      </td>
    ))}
  </tr>
);

const SyncLogs = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [actionFilter, setActionFilter] = useState<ActionType>('All');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const loadLogs = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    try {
      const data = await fetchAuditoriaSync();
      setLogs(data);
      setLastUpdated(new Date());
    } catch (error) {
      console.error('Failed to load sync audit logs', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { loadLogs(); }, [loadLogs]);

  // Auto-refresh cada 30 segundos
  useEffect(() => {
    const interval = setInterval(() => loadLogs(true), 30000);
    return () => clearInterval(interval);
  }, [loadLogs]);

  const filtered = logs.filter(log => {
    if (actionFilter !== 'All' && log.accion !== actionFilter) return false;
    if (dateFrom) {
      const logDate = new Date(log.fechaSincronizacion);
      if (logDate < new Date(dateFrom)) return false;
    }
    if (dateTo) {
      const logDate = new Date(log.fechaSincronizacion);
      const toDate = new Date(dateTo);
      toDate.setHours(23, 59, 59, 999);
      if (logDate > toDate) return false;
    }
    return true;
  });

  const mapsUrl = (lat: number, lng: number) =>
    `https://www.google.com/maps?q=${lat},${lng}`;

  const clearFilters = () => {
    setActionFilter('All');
    setDateFrom('');
    setDateTo('');
  };

  const hasFilters = actionFilter !== 'All' || dateFrom || dateTo;

  return (
    <div className="flex flex-col gap-6 animate-fade-in">

      {/* ── Header ────────────────────────────────────────── */}
      <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
              <span className="material-symbols-outlined text-teal-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>sync_alt</span>
              Auditoría de Sincronización Móvil
            </h2>
            <p className="text-slate-500 text-sm mt-1">
              Bitácora en tiempo real de paquetes de datos sincronizados por la APK offline-first.
            </p>
            {lastUpdated && (
              <p className="text-slate-400 text-xs mt-1.5 font-mono flex items-center gap-1.5">
                <span className={`w-1.5 h-1.5 rounded-full ${refreshing ? 'bg-amber-400 animate-pulse' : 'bg-emerald-500'} inline-block`}></span>
                Última actualización: {lastUpdated.toLocaleTimeString('es-NI')} · Auto-refresh cada 30s
              </p>
            )}
          </div>
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs font-bold text-slate-600 bg-slate-100 px-3 py-1.5 rounded-full">
              {loading ? '…' : `${filtered.length} registros`}
            </span>
            <button
              onClick={() => loadLogs(true)}
              disabled={refreshing}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-semibold transition-all disabled:opacity-50"
            >
              <span className={`material-symbols-outlined text-[16px] ${refreshing ? 'animate-spin' : ''}`}>refresh</span>
              {refreshing ? 'Actualizando...' : 'Actualizar'}
            </button>
          </div>
        </div>

        {/* ── Filters ─────────────────────────────────────── */}
        <div className="mt-4 pt-4 border-t border-slate-100 flex flex-wrap gap-3 items-center">
          {/* Action filter chips */}
          <div className="flex gap-2 items-center">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Acción:</span>
            {(['All', 'Insert', 'Update', 'Delete'] as ActionType[]).map(a => (
              <button
                key={a}
                onClick={() => setActionFilter(a)}
                className={`px-3 py-1 rounded-full text-xs font-bold border transition-all ${
                  actionFilter === a
                    ? a === 'All' ? 'bg-slate-700 text-white border-slate-700' : ACTION_STYLES[a] + ' opacity-100 scale-105'
                    : 'bg-white text-slate-500 border-slate-200 hover:border-slate-400'
                }`}
              >
                {a === 'All' ? 'Todos' : (
                  <span className="flex items-center gap-1">
                    <span className="material-symbols-outlined text-[12px]" style={{ fontVariationSettings: "'FILL' 1" }}>{ACTION_ICONS[a]}</span>
                    {a}
                  </span>
                )}
              </button>
            ))}
          </div>

          {/* Date range */}
          <div className="flex gap-2 items-center ml-0 md:ml-auto">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Desde:</span>
            <input
              type="date"
              value={dateFrom}
              onChange={e => setDateFrom(e.target.value)}
              className="border border-slate-200 rounded-lg px-2 py-1 text-xs text-slate-700 focus:outline-none focus:border-teal-500"
            />
            <span className="text-xs font-semibold text-slate-400">Hasta:</span>
            <input
              type="date"
              value={dateTo}
              onChange={e => setDateTo(e.target.value)}
              className="border border-slate-200 rounded-lg px-2 py-1 text-xs text-slate-700 focus:outline-none focus:border-teal-500"
            />
            {hasFilters && (
              <button onClick={clearFilters} className="text-xs text-rose-500 hover:underline font-semibold flex items-center gap-1">
                <span className="material-symbols-outlined text-[14px]">close</span>
                Limpiar
              </button>
            )}
          </div>
        </div>
      </div>

      {/* ── Table ─────────────────────────────────────────── */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
                <th className="py-3 px-4">Fecha / Hora</th>
                <th className="py-3 px-4">Ganadero</th>
                <th className="py-3 px-4">Finca</th>
                <th className="py-3 px-4 text-center">Tipo Entidad</th>
                <th className="py-3 px-4 text-center">Acción</th>
                <th className="py-3 px-4 text-center">Coordenadas GPS</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                [1,2,3,4,5].map(i => <RowSkeleton key={i} />)
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-14 text-center">
                    <span className="material-symbols-outlined text-slate-300 text-5xl block mb-2">history</span>
                    <p className="text-slate-400 italic text-sm">
                      {hasFilters ? 'No hay registros con los filtros aplicados.' : 'No hay registros de auditoría aún.'}
                    </p>
                    {hasFilters && (
                      <button onClick={clearFilters} className="mt-2 text-teal-600 text-xs hover:underline">
                        Quitar filtros
                      </button>
                    )}
                  </td>
                </tr>
              ) : (
                filtered.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50/80 transition-colors text-xs group">
                    <td className="py-3 px-4 font-semibold text-slate-700 tabular-nums whitespace-nowrap">
                      {new Date(log.fechaSincronizacion).toLocaleString('es-NI')}
                    </td>
                    <td className="py-3 px-4 font-bold text-slate-900">{log.ganaderoNombre}</td>
                    <td className="py-3 px-4 text-slate-600">{log.fincaNombre || <span className="text-slate-300 italic">N/A</span>}</td>
                    <td className="py-3 px-4 text-center">
                      <span className="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 font-bold border border-slate-200">
                        {log.tipoEntidad}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-extrabold ${ACTION_STYLES[log.accion] ?? 'bg-slate-100 text-slate-700'}`}>
                        <span className="material-symbols-outlined text-[12px]" style={{ fontVariationSettings: "'FILL' 1" }}>
                          {ACTION_ICONS[log.accion] ?? 'help'}
                        </span>
                        {log.accion}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      {log.latitud && log.longitud ? (
                        <a
                          href={mapsUrl(log.latitud, log.longitud)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-blue-50 text-blue-700 font-mono font-bold hover:bg-blue-100 transition-colors text-[11px]"
                          title="Ver en Google Maps"
                        >
                          <span className="material-symbols-outlined text-[12px]" style={{ fontVariationSettings: "'FILL' 1" }}>location_on</span>
                          {log.latitud.toFixed(4)}, {log.longitud.toFixed(4)}
                        </a>
                      ) : (
                        <span className="text-slate-300 italic">Sin GPS</span>
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
  );
};

export default SyncLogs;
