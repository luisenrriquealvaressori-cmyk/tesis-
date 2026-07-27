import { useState, useEffect } from 'react';
import { fetchEnfermedades, createEnfermedad, fetchMedicamentos, createMedicamento, fetchRazas } from '../services/api';

const CatalogManagement = () => {
  const [activeTab, setActiveTab] = useState<'enfermedades' | 'medicamentos' | 'razas'>('enfermedades');

  // List states
  const [enfermedades, setEnfermedades] = useState<any[]>([]);
  const [medicamentos, setMedicamentos] = useState<any[]>([]);
  const [razas, setRazas] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Form Enfermedad
  const [nombreEnf, setNombreEnf] = useState('');
  const [descEnf, setDescEnf] = useState('');
  const [sintomas, setSintomas] = useState<string[]>([]);
  const [currentSintoma, setCurrentSintoma] = useState('');
  const [notificacion, setNotificacion] = useState(false);

  // Form Medicamento
  const [nombreMed, setNombreMed] = useState('');
  const [principioActivo, setPrincipioActivo] = useState('');
  const [viaAdmin, setViaAdmin] = useState('Inyectable');
  const [diasRetiro, setDiasRetiro] = useState(0);

  const loadData = async () => {
    try {
      setLoading(true);
      const [enfData, medData, razasData] = await Promise.all([
        fetchEnfermedades(),
        fetchMedicamentos(),
        fetchRazas()
      ]);
      setEnfermedades(enfData);
      setMedicamentos(medData);
      setRazas(razasData);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAddSintoma = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && currentSintoma.trim()) {
      e.preventDefault();
      if (!sintomas.includes(currentSintoma.trim())) {
        setSintomas([...sintomas, currentSintoma.trim()]);
      }
      setCurrentSintoma('');
    }
  };

  const handleRemoveSintoma = (sintomaToRemove: string) => {
    setSintomas(sintomas.filter(s => s !== sintomaToRemove));
  };

  const handleSaveEnfermedad = async () => {
    if (!nombreEnf.trim() || !descEnf.trim()) {
      alert("Por favor completa los campos obligatorios.");
      return;
    }

    try {
      await createEnfermedad({
        nombre: nombreEnf,
        descripcion: descEnf,
        notificacionObligatoria: notificacion,
        sintomas
      });
      setNombreEnf('');
      setDescEnf('');
      setSintomas([]);
      setNotificacion(false);
      loadData();
    } catch (error) {
      console.error(error);
      alert("Fallo al guardar la enfermedad.");
    }
  };

  const handleSaveMedicamento = async () => {
    if (!nombreMed.trim()) {
      alert("Ingresa el nombre comercial del medicamento.");
      return;
    }

    try {
      await createMedicamento({
        nombreComercial: nombreMed,
        principioActivo,
        viaAdministracion: viaAdmin,
        diasRetiroLeche: Number(diasRetiro) || 0
      });
      setNombreMed('');
      setPrincipioActivo('');
      setViaAdmin('Inyectable');
      setDiasRetiro(0);
      loadData();
    } catch (error) {
      console.error(error);
      alert("Fallo al guardar el medicamento.");
    }
  };

  return (
    <div className="flex-1 flex flex-col h-full gap-6">
      <div>
        <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2">
          <span className="material-symbols-outlined text-emerald-600 text-3xl">settings</span>
          Gestión de Catálogos Maestros
        </h2>
        <p className="text-slate-500 text-sm mt-1">Administra los diccionarios clínicos, sanitarios y genéticos del sistema.</p>
      </div>
      
      {/* Selector de Pestañas */}
      <div className="flex border-b border-slate-200 gap-2">
        <button 
          onClick={() => setActiveTab('enfermedades')}
          className={`px-5 py-2.5 text-sm font-bold border-b-2 transition-all ${
            activeTab === 'enfermedades' ? 'border-emerald-600 text-emerald-800 bg-emerald-50/50' : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          🦠 Enfermedades & Síntomas
        </button>
        <button 
          onClick={() => setActiveTab('medicamentos')}
          className={`px-5 py-2.5 text-sm font-bold border-b-2 transition-all ${
            activeTab === 'medicamentos' ? 'border-emerald-600 text-emerald-800 bg-emerald-50/50' : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          💊 Medicamentos & Retiro Sanitario
        </button>
        <button 
          onClick={() => setActiveTab('razas')}
          className={`px-5 py-2.5 text-sm font-bold border-b-2 transition-all ${
            activeTab === 'razas' ? 'border-emerald-600 text-emerald-800 bg-emerald-50/50' : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          🐂 Razas Bovinas
        </button>
      </div>
      
      {/* Pestaña 1: Enfermedades */}
      {activeTab === 'enfermedades' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <div className="lg:col-span-4 bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
            <h3 className="font-bold text-slate-900 text-lg mb-4 border-b border-slate-100 pb-2">Nueva Enfermedad</h3>
            <form className="flex flex-col gap-4">
              <div>
                <label className="text-xs font-bold text-slate-600">Nombre de la Enfermedad *</label>
                <input 
                  value={nombreEnf}
                  onChange={e => setNombreEnf(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none" 
                  placeholder="Ej. Mastitis Infecciosa" 
                />
              </div>
              
              <div>
                <label className="text-xs font-bold text-slate-600">Descripción Clínica *</label>
                <textarea 
                  value={descEnf}
                  onChange={e => setDescEnf(e.target.value)}
                  className="w-full mt-1 p-3 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none resize-none" 
                  placeholder="Síntomas generales..." rows={3}
                ></textarea>
              </div>

              <div className="flex items-center gap-2">
                <input 
                  type="checkbox" 
                  id="notif"
                  checked={notificacion}
                  onChange={e => setNotificacion(e.target.checked)}
                  className="w-4 h-4 text-emerald-600 rounded"
                />
                <label htmlFor="notif" className="text-xs font-bold text-slate-700">Notificación Sanitaria Obligatoria</label>
              </div>
              
              <div>
                <label className="text-xs font-bold text-slate-600">Síntomas Asociados (Enter para agregar)</label>
                <div className="mt-1 min-h-[44px] border border-slate-200 rounded-xl p-2 flex flex-wrap gap-2 bg-slate-50">
                  {sintomas.map(s => (
                    <span key={s} className="inline-flex items-center gap-1 bg-emerald-100 text-emerald-900 text-xs font-bold px-2.5 py-1 rounded-full">
                      {s} 
                      <span onClick={() => handleRemoveSintoma(s)} className="material-symbols-outlined text-xs cursor-pointer hover:text-red-600">close</span>
                    </span>
                  ))}
                  <input 
                    value={currentSintoma}
                    onChange={e => setCurrentSintoma(e.target.value)}
                    onKeyDown={handleAddSintoma}
                    className="flex-1 bg-transparent border-none outline-none text-xs min-w-[120px]" 
                    placeholder="Ej. Fiebre alta..." 
                  />
                </div>
              </div>
              
              <button 
                onClick={handleSaveEnfermedad}
                className="mt-2 bg-emerald-700 hover:bg-emerald-800 text-white font-bold text-sm py-2.5 rounded-xl transition-colors shadow-sm" 
                type="button"
              >
                Guardar Enfermedad
              </button>
            </form>
          </div>
          
          <div className="lg:col-span-8 bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden flex flex-col">
            <div className="p-4 border-b border-slate-200 bg-slate-50 font-bold text-slate-700 text-sm">
              Directorio Clínico Registrado ({enfermedades.length})
            </div>
            <div className="overflow-x-auto flex-1">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-slate-200 text-slate-400 font-bold uppercase">
                    <th className="p-3">Nombre</th>
                    <th className="p-3">Síntomas</th>
                    <th className="p-3 text-center">Estado Sanitario</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {loading ? (
                    <tr><td colSpan={3} className="p-6 text-center text-slate-400">Cargando...</td></tr>
                  ) : enfermedades.map(e => (
                    <tr key={e.id} className="hover:bg-slate-50">
                      <td className="p-3 font-bold text-slate-900">{e.nombre}</td>
                      <td className="p-3 text-slate-600">{e.sintomas?.join(', ') || 'Sin síntomas'}</td>
                      <td className="p-3 text-center">
                        {e.notificacionObligatoria ? (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-rose-100 text-rose-700">Epidémico</span>
                        ) : (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700">Normal</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Pestaña 2: Medicamentos */}
      {activeTab === 'medicamentos' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <div className="lg:col-span-4 bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
            <h3 className="font-bold text-slate-900 text-lg mb-4 border-b border-slate-100 pb-2">Nuevo Medicamento</h3>
            <form className="flex flex-col gap-4">
              <div>
                <label className="text-xs font-bold text-slate-600">Nombre Comercial *</label>
                <input 
                  value={nombreMed}
                  onChange={e => setNombreMed(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none" 
                  placeholder="Ej. Oxitetraciclina 200" 
                />
              </div>

              <div>
                <label className="text-xs font-bold text-slate-600">Principio Activo</label>
                <input 
                  value={principioActivo}
                  onChange={e => setPrincipioActivo(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none" 
                  placeholder="Ej. Oxitetraciclina L.A." 
                />
              </div>

              <div>
                <label className="text-xs font-bold text-slate-600">Vía de Administración</label>
                <select 
                  value={viaAdmin}
                  onChange={e => setViaAdmin(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none"
                >
                  <option value="Inyectable IM/IV">Inyectable IM/IV</option>
                  <option value="Intramamario">Intramamario</option>
                  <option value="Oral">Oral</option>
                  <option value="Tópico / Pour-On">Tópico / Pour-On</option>
                </select>
              </div>

              <div>
                <label className="text-xs font-bold text-amber-800">Días de Retiro Sanitario en Leche (Carencia) *</label>
                <input 
                  type="number"
                  value={diasRetiro}
                  onChange={e => setDiasRetiro(Number(e.target.value))}
                  className="w-full mt-1 px-3 py-2 border border-amber-300 bg-amber-50/50 rounded-xl text-sm font-bold text-amber-900 outline-none" 
                  placeholder="0" 
                />
                <p className="text-[11px] text-amber-700 mt-1">Días durante los cuales la leche debe ser descartada.</p>
              </div>

              <button 
                onClick={handleSaveMedicamento}
                className="mt-2 bg-emerald-700 hover:bg-emerald-800 text-white font-bold text-sm py-2.5 rounded-xl transition-colors shadow-sm" 
                type="button"
              >
                Guardar Medicamento
              </button>
            </form>
          </div>

          <div className="lg:col-span-8 bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden flex flex-col">
            <div className="p-4 border-b border-slate-200 bg-slate-50 font-bold text-slate-700 text-sm">
              Fármacos y Tiempos de Retiro Lácteo ({medicamentos.length})
            </div>
            <div className="overflow-x-auto flex-1">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-slate-200 text-slate-400 font-bold uppercase">
                    <th className="p-3">Nombre Comercial</th>
                    <th className="p-3">Principio Activo</th>
                    <th className="p-3">Vía</th>
                    <th className="p-3 text-center">Días Retiro Leche</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {loading ? (
                    <tr><td colSpan={4} className="p-6 text-center text-slate-400">Cargando...</td></tr>
                  ) : medicamentos.map(m => (
                    <tr key={m.id} className="hover:bg-slate-50">
                      <td className="p-3 font-bold text-slate-900">{m.nombreComercial}</td>
                      <td className="p-3 text-slate-600">{m.principioActivo || 'N/A'}</td>
                      <td className="p-3 text-slate-600">{m.viaAdministracion}</td>
                      <td className="p-3 text-center">
                        {m.diasRetiroLeche > 0 ? (
                          <span className="px-2.5 py-1 rounded-full text-[11px] font-extrabold bg-amber-100 text-amber-800 border border-amber-300">
                            ⚠️ {m.diasRetiroLeche} día(s)
                          </span>
                        ) : (
                          <span className="px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-100 text-emerald-800">
                            0 días (Libre)
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Pestaña 3: Razas Bovinas */}
      {activeTab === 'razas' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
          <h3 className="font-bold text-slate-900 text-lg mb-4 border-b border-slate-100 pb-2">Catálogo de Razas Bovinas</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {razas.map(r => (
              <div key={r.id} className="p-4 border border-slate-200 rounded-xl bg-slate-50/50 hover:border-emerald-500 transition-colors">
                <div className="flex justify-between items-start mb-2">
                  <h4 className="font-bold text-slate-900 text-base">{r.nombre}</h4>
                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                    r.proposito === 1 ? 'bg-blue-100 text-blue-800' :
                    r.proposito === 2 ? 'bg-rose-100 text-rose-800' : 'bg-emerald-100 text-emerald-800'
                  }`}>
                    {r.proposito === 1 ? 'Leche' : r.proposito === 2 ? 'Carne' : 'Doble Propósito'}
                  </span>
                </div>
                <p className="text-xs text-slate-500">Origen: <span className="font-semibold text-slate-700">{r.origenGenetico}</span></p>
                {r.descripcion && <p className="text-xs text-slate-600 mt-2">{r.descripcion}</p>}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default CatalogManagement;
