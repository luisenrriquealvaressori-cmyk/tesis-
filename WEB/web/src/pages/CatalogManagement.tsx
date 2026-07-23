import { useState, useEffect } from 'react';
import { fetchEnfermedades, createEnfermedad } from '../services/api';

const CatalogManagement = () => {
  const [enfermedades, setEnfermedades] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Form state
  const [nombre, setNombre] = useState('');
  const [descripcion, setDescripcion] = useState('');
  const [sintomas, setSintomas] = useState<string[]>([]);
  const [currentSintoma, setCurrentSintoma] = useState('');
  const [notificacion, setNotificacion] = useState(false);

  const loadData = async () => {
    try {
      setLoading(true);
      const data = await fetchEnfermedades();
      setEnfermedades(data);
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

  const handleSave = async () => {
    if (!nombre.trim() || !descripcion.trim()) {
      alert("Por favor llena todos los campos.");
      return;
    }

    try {
      await createEnfermedad({
        nombre,
        descripcion,
        notificacionObligatoria: notificacion,
        sintomas
      });
      // Limpiar form
      setNombre('');
      setDescripcion('');
      setSintomas([]);
      setNotificacion(false);
      // Recargar tabla
      loadData();
    } catch (error) {
      console.error(error);
      alert("Fallo al guardar la enfermedad.");
    }
  };

  return (
    <div className="flex-1 flex flex-col h-full">
      <div className="mb-lg">
        <h2 className="font-headline-xl text-headline-xl text-primary">Gestión de Catálogos</h2>
        <p className="font-body-lg text-body-lg text-on-surface-variant mt-sm">Administra los diccionarios clínicos del sistema.</p>
      </div>
      
      {/* Tabs */}
      <div className="flex border-b border-outline-variant mb-lg overflow-x-auto hide-scrollbar">
        <button className="px-md py-sm font-label-md text-label-md nav-active whitespace-nowrap">
            Enfermedades y Síntomas
        </button>
        <button className="px-md py-sm font-label-md text-label-md text-on-surface-variant hover:text-primary transition-colors whitespace-nowrap border-b-2 border-transparent">
            Fármacos
        </button>
        <button className="px-md py-sm font-label-md text-label-md text-on-surface-variant hover:text-primary transition-colors whitespace-nowrap border-b-2 border-transparent">
            Razas Bovinas
        </button>
      </div>
      
      {/* Layout Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-lg flex-1">
        {/* Form Section */}
        <div className="lg:col-span-4 flex flex-col gap-lg">
          <div className="bg-surface-container-lowest rounded-lg border border-outline-variant p-lg shadow-sm">
            <h3 className="font-title-md text-title-md text-primary mb-md border-b border-outline-variant pb-sm">Nueva Enfermedad</h3>
            <form className="flex flex-col gap-md">
              <div className="flex flex-col gap-xs">
                <label className="font-label-md text-label-md text-on-surface-variant">Nombre</label>
                <input 
                  value={nombre}
                  onChange={e => setNombre(e.target.value)}
                  className="h-[40px] rounded border border-outline-variant px-sm font-body-md text-body-md focus:border-secondary focus:ring-1 focus:ring-secondary outline-none transition-all" 
                  placeholder="Ej. Mastitis Infecciosa" type="text" />
              </div>
              
              <div className="flex flex-col gap-xs">
                <label className="font-label-md text-label-md text-on-surface-variant">Descripción Clínica</label>
                <textarea 
                  value={descripcion}
                  onChange={e => setDescripcion(e.target.value)}
                  className="rounded border border-outline-variant p-sm font-body-md text-body-md focus:border-secondary focus:ring-1 focus:ring-secondary outline-none transition-all resize-none" 
                  placeholder="Descripción detallada..." rows={3}></textarea>
              </div>

              <div className="flex items-center gap-sm mt-xs">
                <input 
                  type="checkbox" 
                  id="notif"
                  checked={notificacion}
                  onChange={e => setNotificacion(e.target.checked)}
                  className="w-4 h-4 text-secondary rounded focus:ring-secondary"
                />
                <label htmlFor="notif" className="font-label-md text-on-surface-variant">Alerta Epidemiológica Obligatoria</label>
              </div>
              
              <div className="flex flex-col gap-xs mt-xs">
                <label className="font-label-md text-label-md text-on-surface-variant">Síntomas Dinámicos (Presiona Enter para añadir)</label>
                <div className="min-h-[40px] rounded border border-outline-variant p-sm flex flex-wrap gap-sm focus-within:border-secondary focus-within:ring-1 focus-within:ring-secondary transition-all bg-surface-container-lowest">
                  {sintomas.map(s => (
                    <span key={s} className="inline-flex items-center gap-xs bg-surface-container py-1 px-2 rounded-full font-label-sm text-label-sm text-on-surface">
                      {s} <span onClick={() => handleRemoveSintoma(s)} className="material-symbols-outlined text-[14px] cursor-pointer hover:text-error">close</span>
                    </span>
                  ))}
                  <input 
                    value={currentSintoma}
                    onChange={e => setCurrentSintoma(e.target.value)}
                    onKeyDown={handleAddSintoma}
                    className="flex-1 bg-transparent border-none outline-none font-body-md text-body-md min-w-[120px] p-0 focus:ring-0 h-6" 
                    placeholder="Ej. Fiebre..." type="text" />
                </div>
              </div>
              
              <div className="flex justify-end mt-sm">
                <button 
                  onClick={handleSave}
                  className="bg-secondary text-on-secondary font-label-md text-label-md px-lg h-[40px] rounded hover:bg-primary-container transition-colors shadow-sm" 
                  type="button">
                  Guardar en Base de Datos
                </button>
              </div>
            </form>
          </div>
        </div>
        
        {/* Table Section */}
        <div className="lg:col-span-8">
          <div className="bg-surface-container-lowest rounded-lg border border-outline-variant overflow-hidden shadow-sm flex flex-col h-full min-h-[500px]">
            <div className="p-md border-b border-outline-variant flex justify-between items-center bg-surface-container-low">
              <h3 className="font-title-md text-title-md text-primary">Directorio Clínico Activo</h3>
              <button className="text-on-surface-variant hover:text-primary transition-colors">
                <span className="material-symbols-outlined">filter_list</span>
              </button>
            </div>
            
            <div className="overflow-x-auto flex-1">
              <table className="w-full text-left border-collapse">
                <thead className="bg-surface border-b border-outline-variant">
                  <tr>
                    <th className="p-sm font-label-md text-label-md text-on-surface-variant font-semibold">Nombre</th>
                    <th className="p-sm font-label-md text-label-md text-on-surface-variant font-semibold">Síntomas</th>
                    <th className="p-sm font-label-md text-label-md text-on-surface-variant font-semibold">Estado/Alerta</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr><td colSpan={3} className="p-4 text-center text-on-surface-variant">Cargando datos del servidor...</td></tr>
                  ) : enfermedades.length === 0 ? (
                    <tr><td colSpan={3} className="p-4 text-center text-on-surface-variant">No hay enfermedades registradas. Añade la primera.</td></tr>
                  ) : (
                    enfermedades.map(e => (
                      <tr key={e.id} className="border-b border-surface-variant table-row-hover transition-colors min-h-[40px]">
                        <td className="p-sm font-body-md text-body-md text-on-surface font-medium">{e.nombre}</td>
                        <td className="p-sm font-body-md text-body-md text-on-surface-variant">
                          {e.sintomas.length > 0 ? e.sintomas.join(', ') : 'Sin síntomas'}
                        </td>
                        <td className="p-sm">
                          {e.notificacionObligatoria ? (
                            <span className="inline-flex items-center px-2 py-0.5 rounded-full text-label-sm font-label-sm bg-error-container text-on-error-container">Notificación Epidémica</span>
                          ) : (
                            <span className="inline-flex items-center px-2 py-0.5 rounded-full text-label-sm font-label-sm bg-secondary-fixed text-on-secondary-fixed-variant">Normal</span>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
            
            <div className="p-sm border-t border-outline-variant flex justify-between items-center bg-surface-container-low">
              <span className="font-label-sm text-label-sm text-on-surface-variant">Total: {enfermedades.length} registros</span>
              <div className="flex gap-sm">
                <button className="p-1 rounded hover:bg-surface-variant text-outline disabled:opacity-50"><span className="material-symbols-outlined text-[18px]">chevron_left</span></button>
                <button className="p-1 rounded hover:bg-surface-variant text-outline"><span className="material-symbols-outlined text-[18px]">chevron_right</span></button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CatalogManagement;
