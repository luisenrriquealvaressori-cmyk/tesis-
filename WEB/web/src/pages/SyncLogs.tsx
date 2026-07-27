import { useEffect, useState } from 'react';
import { fetchAuditoriaSync } from '../services/api';

const SyncLogs = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadLogs = async () => {
      try {
        const data = await fetchAuditoriaSync();
        setLogs(data);
      } catch (error) {
        console.error('Failed to load sync audit logs', error);
      } finally {
        setLoading(false);
      }
    };

    loadLogs();
  }, []);

  return (
    <div className="flex flex-col gap-6">
      {/* Header Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2">
            <span className="material-symbols-outlined text-teal-600 text-3xl">sync_alt</span>
            Auditoría de Sincronización Móvil
          </h2>
          <p className="text-slate-500 text-sm mt-1">Bitácora en tiempo real de paquetes de datos sincronizados por la APK offline-first en el campo.</p>
        </div>
        <div className="flex items-center gap-2 text-xs font-bold text-slate-600 bg-slate-100 px-3 py-1.5 rounded-full">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          Conexión API Neon DB Activa
        </div>
      </div>

      {/* Logs Table */}
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
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">Cargando logs de sincronización...</td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400 italic">No hay registros de auditoría de sincronización aún.</td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50/80 transition-colors text-xs">
                    <td className="py-3 px-4 font-bold text-slate-700">
                      {new Date(log.fechaSincronizacion).toLocaleString('es-NI')}
                    </td>
                    <td className="py-3 px-4 font-bold text-slate-900">{log.ganaderoNombre}</td>
                    <td className="py-3 px-4 text-slate-600">{log.fincaNombre || 'N/A'}</td>
                    <td className="py-3 px-4 text-center">
                      <span className="px-2.5 py-1 rounded-md bg-slate-100 font-bold text-slate-700">
                        {log.tipoEntidad}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className={`px-2.5 py-1 rounded-md font-extrabold ${
                        log.accion === 'Insert' ? 'bg-emerald-100 text-emerald-800' :
                        log.accion === 'Update' ? 'bg-blue-100 text-blue-800' : 'bg-rose-100 text-rose-800'
                      }`}>
                        {log.accion}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center font-mono text-slate-500">
                      {log.latitud && log.longitud 
                        ? `${log.latitud.toFixed(4)}, ${log.longitud.toFixed(4)}`
                        : 'Sin GPS'}
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
