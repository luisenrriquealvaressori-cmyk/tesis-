import { useEffect, useState } from 'react';
import { fetchMapaFincas } from '../services/api';

const FarmMap = () => {
  const [fincas, setFincas] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const loadFincas = async () => {
      try {
        const data = await fetchMapaFincas();
        setFincas(data);
      } catch (error) {
        console.error('Failed to load fincas directory', error);
      } finally {
        setLoading(false);
      }
    };

    loadFincas();
  }, []);

  const filteredFincas = fincas.filter(f => 
    f.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
    f.ganaderoNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
    f.municipio.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex flex-col gap-6">
      {/* Header Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2">
            <span className="material-symbols-outlined text-emerald-600 text-3xl">landscape</span>
            Directorio y Mapa de Fincas
          </h2>
          <p className="text-slate-500 text-sm mt-1">Gestión centralizada de propiedades rurales, censos ganaderos y UGM acumulados.</p>
        </div>
        <div className="relative w-full md:w-72">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-xl">search</span>
          <input
            type="text"
            placeholder="Buscar por finca, ganadero..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
          />
        </div>
      </div>

      {/* Directory Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
                <th className="py-3 px-4">Finca</th>
                <th className="py-3 px-4">Propietario / Ganadero</th>
                <th className="py-3 px-4">Ubicación Geográfica</th>
                <th className="py-3 px-4 text-center">Censo Bovino</th>
                <th className="py-3 px-4 text-center">UGM Totales</th>
                <th className="py-3 px-4 text-center">Estado Sanitario</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">Cargando directorio de fincas...</td>
                </tr>
              ) : filteredFincas.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400 italic">No se encontraron fincas con el criterio de búsqueda.</td>
                </tr>
              ) : (
                filteredFincas.map((f) => (
                  <tr key={f.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3.5 px-4 font-bold text-slate-900 flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-emerald-100 text-emerald-800 font-bold flex items-center justify-center">
                        <span className="material-symbols-outlined text-lg">domain</span>
                      </div>
                      <div>
                        <p className="font-bold text-slate-900">{f.nombre}</p>
                        <p className="text-xs text-slate-400">ID: {f.id.substring(0, 8)}...</p>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 text-slate-700 font-semibold">{f.ganaderoNombre}</td>
                    <td className="py-3.5 px-4 text-slate-600">
                      <div className="flex items-center gap-1">
                        <span className="material-symbols-outlined text-sm text-emerald-600">location_on</span>
                        <span>{f.municipio} {f.comarca ? `• ${f.comarca}` : ''}</span>
                      </div>
                      {f.latitud && f.longitud && (
                        <p className="text-[11px] text-slate-400 font-mono mt-0.5">
                          GPS: {f.latitud.toFixed(4)}, {f.longitud.toFixed(4)}
                        </p>
                      )}
                    </td>
                    <td className="py-3.5 px-4 text-center font-extrabold text-slate-900">
                      {f.totalGanado} cabezas
                    </td>
                    <td className="py-3.5 px-4 text-center font-extrabold text-teal-700">
                      {f.totalUGM} UGM
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      {f.tieneAlertasSanitarias ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-rose-100 text-rose-700 font-bold text-[10px]">
                          <span className="w-1.5 h-1.5 rounded-full bg-rose-600 animate-pulse"></span>
                          Alerta Activa
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 font-bold text-[10px]">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                          Sano
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
  );
};

export default FarmMap;
