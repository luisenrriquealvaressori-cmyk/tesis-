import { useEffect, useState, useCallback } from 'react';
import { fetchMapaFincas, fetchFincaDetalle } from '../services/api';
import { useNavigate } from 'react-router-dom';

// Nicaragua centroide
const NIC_CENTER = { lat: 12.865, lng: -85.207 };

// Generador de color para marcadores SVG
const markerSvg = (alert: boolean) => encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="40" viewBox="0 0 32 40">
  <path d="M16 0C7.163 0 0 7.163 0 16c0 12 16 24 16 24S32 28 32 16C32 7.163 24.837 0 16 0z" 
    fill="${alert ? '#ef4444' : '#10b981'}"/>
  <circle cx="16" cy="16" r="7" fill="white" opacity="0.9"/>
  <circle cx="16" cy="16" r="4" fill="${alert ? '#ef4444' : '#10b981'}"/>
</svg>`);

const FarmMap = () => {
  const [fincas, setFincas] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedFinca, setSelectedFinca] = useState<any | null>(null);
  const [detalle, setDetalle] = useState<any | null>(null);
  const [loadingDetalle, setLoadingDetalle] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [mapLoaded, setMapLoaded] = useState(false);
  const navigate = useNavigate();

  // Cargar Leaflet dinámicamente
  useEffect(() => {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    document.head.appendChild(link);

    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.onload = () => setMapLoaded(true);
    document.head.appendChild(script);

    return () => {
      document.head.removeChild(link);
      document.head.removeChild(script);
    };
  }, []);

  useEffect(() => {
    const load = async () => {
      try {
        const data = await fetchMapaFincas();
        setFincas(data);
      } catch (e) { console.error(e); }
      finally { setLoading(false); }
    };
    load();
  }, []);

  // Inicializar mapa Leaflet cuando esté listo
  useEffect(() => {
    if (!mapLoaded || loading || fincas.length === 0) return;
    const L = (window as any).L;
    if (!L) return;

    const existing = (window as any)._leafletMap;
    if (existing) { existing.remove(); }

    const map = L.map('farm-map', { center: [NIC_CENTER.lat, NIC_CENTER.lng], zoom: 7 });
    (window as any)._leafletMap = map;

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors'
    }).addTo(map);

    fincas.forEach(f => {
      if (!f.latitud || !f.longitud) return;
      const icon = L.divIcon({
        html: `<img src="data:image/svg+xml,${markerSvg(f.tieneAlertasSanitarias)}" style="width:32px;height:40px"/>`,
        iconSize: [32, 40], iconAnchor: [16, 40], className: ''
      });
      const marker = L.marker([f.latitud, f.longitud], { icon }).addTo(map);
      marker.on('click', () => handleSelectFinca(f));
    });

    // Ajustar vista si hay fincas con GPS
    const conGps = fincas.filter(f => f.latitud && f.longitud);
    if (conGps.length > 0) {
      const bounds = L.latLngBounds(conGps.map((f: any) => [f.latitud, f.longitud]));
      map.fitBounds(bounds, { padding: [40, 40] });
    }
  }, [mapLoaded, loading, fincas]);

  const handleSelectFinca = useCallback(async (finca: any) => {
    setSelectedFinca(finca);
    setDetalle(null);
    setLoadingDetalle(true);
    try {
      const d = await fetchFincaDetalle(finca.id);
      setDetalle(d);
    } catch (e) { console.error(e); }
    finally { setLoadingDetalle(false); }
  }, []);

  const filtered = fincas.filter(f =>
    f.nombre?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    f.ganaderoNombre?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    f.municipio?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex flex-col gap-4 animate-fade-in">

      {/* ── Header ──────────────────────────────────────── */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
            <span className="material-symbols-outlined text-emerald-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>map</span>
            Mapa Interactivo de Fincas
          </h2>
          <p className="text-slate-500 text-sm mt-0.5">
            {loading ? 'Cargando fincas...' : `${fincas.filter(f => f.latitud && f.longitud).length} de ${fincas.length} fincas con GPS`}
          </p>
        </div>
        <div className="flex items-center gap-4 flex-wrap">
          <div className="flex items-center gap-3 text-xs font-semibold">
            <span className="flex items-center gap-1.5"><span className="w-3 h-3 rounded-full bg-emerald-500"></span> Sin alertas</span>
            <span className="flex items-center gap-1.5"><span className="w-3 h-3 rounded-full bg-rose-500"></span> Con alertas</span>
          </div>
          <div className="relative w-64">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-lg">search</span>
            <input
              type="text"
              placeholder="Buscar finca, ganadero..."
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
            />
          </div>
        </div>
      </div>

      {/* ── Main layout ──────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">

        {/* Lista lateral */}
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden flex flex-col" style={{ maxHeight: '70vh' }}>
          <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Lista de Fincas</span>
            <span className="text-xs font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">{filtered.length}</span>
          </div>
          <div className="overflow-y-auto custom-scrollbar flex-1">
            {loading ? (
              <div className="p-4 space-y-2">
                {[1,2,3,4,5].map(i => <div key={i} className="skeleton h-14 rounded-xl"></div>)}
              </div>
            ) : filtered.length === 0 ? (
              <div className="p-8 text-center text-slate-400 italic text-sm">Sin resultados</div>
            ) : (
              filtered.map(f => (
                <button
                  key={f.id}
                  onClick={() => handleSelectFinca(f)}
                  className={`w-full text-left px-4 py-3 border-b border-slate-100 hover:bg-emerald-50/60 transition-colors flex items-center gap-3 group ${selectedFinca?.id === f.id ? 'bg-emerald-50 border-l-4 border-l-emerald-500' : ''}`}
                >
                  <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${f.tieneAlertasSanitarias ? 'bg-rose-100' : 'bg-emerald-100'}`}>
                    <span className={`material-symbols-outlined text-base ${f.tieneAlertasSanitarias ? 'text-rose-600' : 'text-emerald-700'}`} style={{ fontVariationSettings: "'FILL' 1" }}>
                      {f.tieneAlertasSanitarias ? 'warning' : 'domain'}
                    </span>
                  </div>
                  <div className="overflow-hidden flex-1">
                    <p className="font-bold text-slate-900 text-sm truncate">{f.nombre}</p>
                    <p className="text-xs text-slate-500 truncate">{f.ganaderoNombre} · {f.municipio}</p>
                  </div>
                  <div className="text-right shrink-0">
                    <p className="text-xs font-extrabold text-slate-700">{f.totalGanado}</p>
                    <p className="text-[10px] text-slate-400">cab</p>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>

        {/* Mapa + ficha */}
        <div className="lg:col-span-2 flex flex-col gap-4">
          {/* Mapa */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden" style={{ height: '400px' }}>
            {loading || !mapLoaded ? (
              <div className="h-full flex flex-col items-center justify-center gap-3 bg-slate-50">
                <span className="material-symbols-outlined text-slate-300 text-6xl animate-pulse">map</span>
                <p className="text-slate-400 text-sm">Cargando mapa...</p>
              </div>
            ) : (
              <div id="farm-map" style={{ width: '100%', height: '100%', zIndex: 1 }}></div>
            )}
          </div>

          {/* Ficha de finca seleccionada */}
          {selectedFinca && (
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 animate-slide-up">
              {loadingDetalle ? (
                <div className="space-y-3">
                  <div className="skeleton h-7 w-1/2 rounded"></div>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                    {[1,2,3,4].map(i => <div key={i} className="skeleton h-16 rounded-xl"></div>)}
                  </div>
                  <div className="skeleton h-4 w-3/4 rounded"></div>
                </div>
              ) : detalle ? (
                <>
                  {/* Header ficha */}
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <h3 className="text-xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
                        <span className="material-symbols-outlined text-emerald-600" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
                        {detalle.nombre}
                      </h3>
                      <p className="text-sm text-slate-500 mt-0.5">
                        <span className="font-semibold text-slate-700">{detalle.ganaderoNombre}</span>
                        {' · '}{detalle.municipio}{detalle.comarca ? ` · ${detalle.comarca}` : ''}
                        {' · '}<span className="font-mono text-xs">{detalle.ganaderoTelefono}</span>
                      </p>
                      {detalle.latitud !== 0 && (
                        <a
                          href={`https://www.google.com/maps?q=${detalle.latitud},${detalle.longitud}`}
                          target="_blank" rel="noopener noreferrer"
                          className="inline-flex items-center gap-1 text-xs text-blue-600 hover:underline mt-0.5"
                        >
                          <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>location_on</span>
                          Ver en Google Maps
                        </a>
                      )}
                    </div>
                    {detalle.tieneAlertasSanitarias && (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-rose-100 text-rose-700 font-bold text-xs shrink-0">
                        <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-pulse"></span>
                        Alerta Activa
                      </span>
                    )}
                  </div>

                  {/* KPIs */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
                    {[
                      { label: 'Total Animales', value: detalle.totalAnimales, icon: 'pets', color: 'emerald' },
                      { label: 'Producción Hoy', value: `${detalle.produccionHoyLitros} L`, icon: 'water_drop', color: 'blue' },
                      { label: 'UGM Totales', value: detalle.totalUGM, icon: 'scale', color: 'teal' },
                      { label: 'Enfermos', value: detalle.animalesEnfermos, icon: 'vaccines', color: detalle.animalesEnfermos > 0 ? 'rose' : 'slate' },
                    ].map(kpi => (
                      <div key={kpi.label} className={`rounded-xl p-3 bg-${kpi.color}-50 border border-${kpi.color}-100 text-center`}>
                        <span className={`material-symbols-outlined text-${kpi.color}-600 text-2xl block mb-1`} style={{ fontVariationSettings: "'FILL' 1" }}>{kpi.icon}</span>
                        <p className={`text-xl font-black text-${kpi.color}-900`}>{kpi.value}</p>
                        <p className={`text-[10px] font-bold text-${kpi.color}-600 uppercase tracking-wide`}>{kpi.label}</p>
                      </div>
                    ))}
                  </div>

                  {/* Desglose animales */}
                  <div className="flex items-center gap-4 text-xs text-slate-600 mb-4">
                    <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-pink-400"></span> {detalle.totalHembras} Hembras</span>
                    <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-blue-400"></span> {detalle.totalMachos} Machos</span>
                    <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-slate-400"></span> {detalle.produccionHoyKg} kg hoy</span>
                  </div>

                  {/* Últimas enfermedades */}
                  {detalle.ultimosSalud && detalle.ultimosSalud.length > 0 && (
                    <div className="mb-4">
                      <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Últimos registros de salud</p>
                      <div className="space-y-1.5 max-h-28 overflow-y-auto custom-scrollbar">
                        {detalle.ultimosSalud.slice(0, 5).map((rs: any) => (
                          <div key={rs.id} className="flex items-center gap-2 text-xs bg-rose-50 rounded-lg px-3 py-1.5 border border-rose-100">
                            <span className="material-symbols-outlined text-rose-500 text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>medical_services</span>
                            <span className="font-bold text-slate-800">{rs.animalIdentificacion}</span>
                            <span className="text-slate-500">—</span>
                            <span className="text-rose-700 font-semibold">{rs.enfermedad}</span>
                            {rs.medicamentos.length > 0 && <span className="text-slate-400 ml-auto">{rs.medicamentos.join(', ')}</span>}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Botón ver detalles completos */}
                  <button
                    onClick={() => navigate(`/farms/${detalle.id}`)}
                    className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-600 text-white font-bold text-sm hover:from-emerald-600 hover:to-teal-700 transition-all hover:scale-[1.01]"
                  >
                    <span className="material-symbols-outlined text-[18px]">open_in_new</span>
                    Ver ficha completa de la finca
                  </button>
                </>
              ) : null}
            </div>
          )}

          {/* Empty state when no finca selected */}
          {!selectedFinca && !loading && (
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-8 text-center">
              <span className="material-symbols-outlined text-slate-200 text-6xl block mb-3">touch_app</span>
              <p className="text-slate-500 font-semibold">Selecciona un marcador en el mapa</p>
              <p className="text-slate-400 text-sm mt-1">o haz clic en una finca de la lista para ver su ficha</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default FarmMap;
