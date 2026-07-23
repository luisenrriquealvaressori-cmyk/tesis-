
const FarmMap = () => {
  return (
    <div className="flex-1 flex flex-col h-full gap-gutter">
      <div className="flex justify-between items-end shrink-0">
        <div>
          <h2 className="font-headline-xl text-headline-xl text-primary">Directorio de Fincas</h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant mt-1">Gestión centralizada de propiedades y recursos ganaderos.</p>
        </div>
        <button className="hidden md:flex items-center gap-sm bg-secondary text-on-secondary px-lg py-2 rounded-lg font-label-md text-label-md hover:bg-primary transition-colors shadow-sm">
          <span className="material-symbols-outlined text-sm">add</span>
          Nueva Finca
        </button>
      </div>

      <div className="flex-1 flex gap-gutter overflow-hidden relative">
        <div className="flex-1 flex flex-col bg-surface-container-lowest border border-outline-variant rounded-xl shadow-sm overflow-hidden transition-all duration-300">
          <div className="p-md border-b border-outline-variant flex flex-wrap gap-md justify-between items-center bg-surface-bright">
            <div className="flex items-center gap-sm">
              <button className="flex items-center gap-xs px-sm py-1.5 border border-outline-variant rounded-md text-on-surface-variant hover:bg-surface-container-low font-label-md text-label-md transition-colors">
                <span className="material-symbols-outlined text-sm">filter_list</span>
                Filtros
              </button>
              <span className="h-4 w-px bg-outline-variant mx-sm"></span>
              <span className="font-label-sm text-label-sm text-outline uppercase tracking-wider">Mostrando 45 Resultados</span>
            </div>
            <div className="flex items-center gap-sm">
              <button className="p-1.5 text-on-surface-variant hover:bg-surface-container-low rounded-md border border-outline-variant transition-colors" title="Exportar CSV">
                <span className="material-symbols-outlined text-sm">download</span>
              </button>
            </div>
          </div>

          <div className="flex-1 overflow-auto custom-scrollbar">
            <table className="w-full text-left border-collapse min-w-[800px]">
              <thead className="sticky top-0 bg-surface-container z-10 shadow-[0_1px_0_#e1e2e4]">
                <tr>
                  <th className="px-md py-3 font-label-md text-label-md text-on-surface-variant w-16">ID</th>
                  <th className="px-md py-3 font-label-md text-label-md text-on-surface-variant">Nombre de la Finca</th>
                  <th className="px-md py-3 font-label-md text-label-md text-on-surface-variant">Dueño</th>
                  <th className="px-md py-3 font-label-md text-label-md text-on-surface-variant">Ubicación</th>
                  <th className="px-md py-3 font-label-md text-label-md text-on-surface-variant text-right">Total Ganado</th>
                </tr>
              </thead>
              <tbody className="bg-surface-container-lowest divide-y divide-outline-variant">
                {[
                  { id: 'FIN-001', name: 'Finca El Encanto', owner: 'Carlos Mendoza', location: 'Valle del Cauca', count: '1,245' },
                  { id: 'FIN-002', name: 'La Esperanza', owner: 'Maria Rodriguez', location: 'Antioquia', count: '850' },
                  { id: 'FIN-003', name: 'Hacienda San José', owner: 'Inversiones Agrícolas SA', location: 'Meta', count: '3,420' },
                  { id: 'FIN-004', name: 'Los Robles', owner: 'Familia Torres', location: 'Cundinamarca', count: '412' }
                ].map((farm) => (
                  <tr key={farm.id} className="table-row-hover transition-colors cursor-pointer group">
                    <td className="px-md py-4 font-body-md text-body-md text-on-surface-variant group-hover:text-primary transition-colors">{farm.id}</td>
                    <td className="px-md py-4 font-body-md text-body-md font-medium text-on-surface group-hover:text-primary transition-colors">{farm.name}</td>
                    <td className="px-md py-4 font-body-md text-body-md text-on-surface-variant">{farm.owner}</td>
                    <td className="px-md py-4 font-body-md text-body-md text-on-surface-variant flex items-center gap-xs">
                      <span className="material-symbols-outlined text-[16px] text-outline">location_on</span>
                      {farm.location}
                    </td>
                    <td className="px-md py-4 font-body-md text-body-md font-medium text-on-surface text-right">{farm.count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          
          <div className="p-sm border-t border-outline-variant flex justify-between items-center bg-surface-container-low">
            <span className="font-label-sm text-label-sm text-on-surface-variant ml-sm">Página 1 de 5</span>
            <div className="flex gap-sm">
              <button className="p-1 rounded hover:bg-surface-variant text-outline disabled:opacity-50"><span className="material-symbols-outlined text-[18px]">chevron_left</span></button>
              <button className="p-1 rounded hover:bg-surface-variant text-outline"><span className="material-symbols-outlined text-[18px]">chevron_right</span></button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FarmMap;
