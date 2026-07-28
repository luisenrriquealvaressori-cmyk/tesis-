import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchFincaDetalle } from '../services/api';

interface AnimalDrawerProps {
  animal: any | null;
  onClose: () => void;
}



/**
 * Panel lateral deslizante con detalle completo de un animal.
 * Muestra historial de salud, KPIs individuales, y acceso rápido a la finca.
 */
const AnimalDrawer = ({ animal, onClose }: AnimalDrawerProps) => {
  const navigate = useNavigate();
  const [historial, setHistorial] = useState<any[]>([]);
  const [loadingHistorial, setLoadingHistorial] = useState(false);
  const [alertSemaforo, setAlertSemaforo] = useState<'verde' | 'amarillo' | 'rojo'>('verde');

  // Cargar historial médico del animal a través del detalle de su finca
  useEffect(() => {
    if (!animal) { setHistorial([]); return; }

    const calcSemaforo = () => {
      if (animal.estado === 'Enferma') { setAlertSemaforo('rojo'); return; }
      if (animal.estado === 'En Tratamiento') { setAlertSemaforo('amarillo'); return; }
      // Lógica: si no se ha registrado salud reciente, amarillo
      setAlertSemaforo('verde');
    };
    calcSemaforo();

    const load = async () => {
      setLoadingHistorial(true);
      try {
        const fincaData = await fetchFincaDetalle(animal.fincaId);
        const registros: any[] = fincaData?.ultimosSalud ?? [];
        // Filtrar registros que correspondan al animal actual (por identificación)
        const propios = registros.filter(
          (r: any) => r.animalIdentificacion === animal.identificacion
        );
        setHistorial(propios);
      } catch (e) {
        setHistorial([]);
      } finally {
        setLoadingHistorial(false);
      }
    };
    load();
  }, [animal]);

  if (!animal) return null;

  const edad = animal.edadMeses >= 12
    ? `${Math.floor(animal.edadMeses / 12)} año${Math.floor(animal.edadMeses / 12) !== 1 ? 's' : ''} ${animal.edadMeses % 12}m`
    : `${animal.edadMeses} meses`;

  const categoriaEdad = animal.edadMeses >= 24 ? 'Adulto' : animal.edadMeses >= 12 ? 'Joven' : 'Cría';
  const ugm = animal.edadMeses >= 24
    ? (animal.sexo === 'Macho' ? 1.2 : 1.0)
    : animal.edadMeses >= 12 ? 0.7 : 0.4;

  const semaforoColor = {
    verde: 'bg-emerald-400 text-white',
    amarillo: 'bg-amber-400 text-white',
    rojo: 'bg-rose-500 text-white',
  }[alertSemaforo];

  const semaforoLabel = {
    verde: '✓ En orden',
    amarillo: '⚠ Requiere atención',
    rojo: '✗ Alerta activa',
  }[alertSemaforo];

  return (
    <>
      {/* Overlay */}
      <div
        className="fixed inset-0 bg-black/30 backdrop-blur-[2px] z-40 animate-fade-in"
        onClick={onClose}
      />

      {/* Panel */}
      <div className="fixed right-0 top-0 h-full w-full max-w-md bg-white shadow-2xl z-50 flex flex-col animate-slide-in-right overflow-hidden">

        {/* ── Header del panel ───────────────────────────────── */}
        <div className="bg-gradient-to-r from-[#012d1d] to-[#0b4d34] px-5 pt-5 pb-4 shrink-0">
          <div className="flex items-start justify-between mb-3">
            <div>
              <p className="text-emerald-300/80 text-xs font-semibold uppercase tracking-widest mb-1">Ficha del Animal</p>
              <h2 className="text-white text-2xl font-extrabold font-mono tracking-wider" style={{ fontFamily: 'Outfit, monospace' }}>
                {animal.identificacion}
              </h2>
              <p className="text-emerald-200/80 text-sm mt-0.5">{animal.raza} · {animal.sexo === 'Hembra' ? '♀ Hembra' : '♂ Macho'}</p>
            </div>
            <button
              onClick={onClose}
              className="p-2 rounded-xl text-white/60 hover:text-white hover:bg-white/10 transition-colors mt-1"
            >
              <span className="material-symbols-outlined text-[20px]">close</span>
            </button>
          </div>

          {/* Semáforo de estado */}
          <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-bold ${semaforoColor}`}>
            <span className="w-2 h-2 rounded-full bg-white/70"></span>
            {semaforoLabel}
          </div>
        </div>

        {/* ── Contenido scrollable ────────────────────────────── */}
        <div className="flex-1 overflow-y-auto custom-scrollbar">

          {/* KPIs del animal */}
          <div className="grid grid-cols-3 divide-x divide-slate-100 border-b border-slate-100">
            {[
              { label: 'Edad', value: edad, icon: 'calendar_today', color: 'text-slate-700' },
              { label: 'Categoría', value: categoriaEdad, icon: 'category', color: 'text-teal-700' },
              { label: 'UGM', value: ugm.toFixed(1), icon: 'scale', color: 'text-violet-700' },
            ].map((kpi, i) => (
              <div key={i} className="flex flex-col items-center py-4 gap-1">
                <span className={`material-symbols-outlined text-[20px] ${kpi.color}`} style={{ fontVariationSettings: "'FILL' 1" }}>{kpi.icon}</span>
                <p className={`text-base font-black ${kpi.color}`}>{kpi.value}</p>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wide">{kpi.label}</p>
              </div>
            ))}
          </div>

          {/* Info de la finca */}
          <div className="px-5 py-4 border-b border-slate-100">
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Finca de Origen</p>
            <button
              onClick={() => { navigate(`/farms/${animal.fincaId}`); onClose(); }}
              className="flex items-center gap-3 w-full text-left group"
            >
              <div className="w-10 h-10 rounded-xl bg-emerald-100 flex items-center justify-center shrink-0 group-hover:bg-emerald-200 transition-colors">
                <span className="material-symbols-outlined text-emerald-700 text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
              </div>
              <div>
                <p className="font-bold text-slate-900 group-hover:text-emerald-700 transition-colors">{animal.finca}</p>
                <p className="text-xs text-slate-500">{animal.ganadero}</p>
              </div>
              <span className="material-symbols-outlined text-slate-300 group-hover:text-emerald-600 ml-auto text-[18px] transition-colors">arrow_forward_ios</span>
            </button>
          </div>

          {/* Datos biológicos */}
          <div className="px-5 py-4 border-b border-slate-100">
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-3">Datos Biológicos</p>
            <div className="space-y-2.5">
              {[
                { label: 'Fecha de Nacimiento', value: new Date(animal.fechaNacimiento).toLocaleDateString('es-NI', { dateStyle: 'long' }) },
                { label: 'Sexo', value: animal.sexo === 'Hembra' ? '♀ Hembra' : '♂ Macho' },
                { label: 'Raza', value: animal.raza },
                { label: 'Estado de Salud', value: animal.estado },
              ].map((item, i) => (
                <div key={i} className="flex items-center justify-between text-sm">
                  <span className="text-slate-500">{item.label}</span>
                  <span className="font-semibold text-slate-900 text-right max-w-[55%]">{item.value}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Historial clínico */}
          <div className="px-5 py-4">
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-3">Historial Clínico Individual</p>

            {loadingHistorial ? (
              <div className="space-y-2">
                {[1, 2].map(i => (
                  <div key={i} className="skeleton h-16 rounded-xl"></div>
                ))}
              </div>
            ) : historial.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-8 gap-2">
                <span className="material-symbols-outlined text-slate-200 text-5xl" style={{ fontVariationSettings: "'FILL' 1" }}>health_and_safety</span>
                <p className="text-slate-400 text-sm font-medium">Sin registros clínicos</p>
                <p className="text-slate-300 text-xs text-center">Este animal no tiene incidencias médicas registradas en los últimos periodos.</p>
              </div>
            ) : (
              <div className="space-y-3">
                {historial.map((rs: any, i: number) => (
                  <div key={i} className="flex gap-3">
                    <div className="flex flex-col items-center">
                      <div className="w-8 h-8 rounded-full bg-rose-100 flex items-center justify-center shrink-0">
                        <span className="material-symbols-outlined text-rose-600 text-[16px]" style={{ fontVariationSettings: "'FILL' 1" }}>medical_services</span>
                      </div>
                      {i < historial.length - 1 && <div className="w-0.5 bg-slate-100 flex-1 mt-1"></div>}
                    </div>
                    <div className="pb-4 flex-1">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-xs font-bold text-rose-700 bg-rose-50 px-2 py-0.5 rounded-full border border-rose-100">{rs.enfermedad}</span>
                        <span className="text-[10px] text-slate-400 font-mono">{new Date(rs.fechaDeteccion).toLocaleDateString('es-NI')}</span>
                      </div>
                      {rs.medicamentos?.length > 0 && (
                        <p className="text-xs text-slate-500 mt-1">
                          <span className="font-semibold">Medicamentos: </span>{rs.medicamentos.join(', ')}
                        </p>
                      )}
                      {rs.observaciones && (
                        <p className="text-xs text-slate-400 mt-1 italic">"{rs.observaciones}"</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* ── Footer de acciones ──────────────────────────────── */}
        <div className="px-5 py-4 border-t border-slate-100 bg-slate-50 shrink-0">
          <button
            onClick={() => { navigate(`/farms/${animal.fincaId}`); onClose(); }}
            className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-bold transition-all hover:scale-[1.01] shadow-sm"
          >
            <span className="material-symbols-outlined text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
            Ver Finca Completa
          </button>
        </div>
      </div>
    </>
  );
};

export default AnimalDrawer;
