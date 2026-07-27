import { useEffect, useState } from 'react';
import { fetchGanaderos } from '../services/api';

const FarmersManagement = () => {
  const [ganaderos, setGanaderos] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const loadGanaderos = async () => {
      try {
        const data = await fetchGanaderos();
        setGanaderos(data);
      } catch (error) {
        console.error('Failed to load ganaderos list', error);
      } finally {
        setLoading(false);
      }
    };

    loadGanaderos();
  }, []);

  const filteredGanaderos = ganaderos.filter(g => 
    g.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
    g.telefono.includes(searchTerm) ||
    g.municipio.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex flex-col gap-6">
      {/* Header Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2">
            <span className="material-symbols-outlined text-emerald-600 text-3xl">groups</span>
            Padrón Institucional de Ganaderos
          </h2>
          <p className="text-slate-500 text-sm mt-1">Usuarios registrados en la aplicación móvil con sus propiedades y censos ganaderos vinculados.</p>
        </div>
        <div className="relative w-full md:w-72">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-xl">search</span>
          <input
            type="text"
            placeholder="Buscar por nombre, teléfono..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
          />
        </div>
      </div>

      {/* Tabla de Ganaderos */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
                <th className="py-3 px-4">Ganadero</th>
                <th className="py-3 px-4">Teléfono</th>
                <th className="py-3 px-4">Municipio / Comarca</th>
                <th className="py-3 px-4 text-center">Fincas Registradas</th>
                <th className="py-3 px-4 text-center">Ganado Monitoreado</th>
                <th className="py-3 px-4 text-center">Fecha Registro</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">Cargando padrón de ganaderos...</td>
                </tr>
              ) : filteredGanaderos.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400 italic">No se encontraron ganaderos que coincidan con la búsqueda.</td>
                </tr>
              ) : (
                filteredGanaderos.map((g) => (
                  <tr key={g.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3.5 px-4 font-bold text-slate-900 flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-emerald-100 text-emerald-800 font-bold flex items-center justify-center text-sm">
                        {g.nombre.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <p className="font-bold text-slate-900">{g.nombre}</p>
                        <p className="text-xs text-slate-400 font-medium">ID: {g.id.substring(0, 8)}...</p>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 text-slate-700 font-semibold">{g.telefono}</td>
                    <td className="py-3.5 px-4 text-slate-600">
                      {g.municipio} {g.comarca ? `• ${g.comarca}` : ''}
                    </td>
                    <td className="py-3.5 px-4 text-center font-extrabold text-emerald-700">
                      {g.totalFincas} finca(s)
                    </td>
                    <td className="py-3.5 px-4 text-center font-extrabold text-teal-700">
                      {g.totalAnimales} cabezas
                    </td>
                    <td className="py-3.5 px-4 text-center text-slate-500 text-xs">
                      {new Date(g.createdAt).toLocaleDateString('es-NI')}
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

export default FarmersManagement;
