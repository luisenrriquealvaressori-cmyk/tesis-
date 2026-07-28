import { useEffect, useState } from 'react';
import { fetchUsuariosWeb, registerWebUserApi } from '../services/api';
import { useAuth } from '../context/AuthContext';

const UsersManagement = () => {
  const { rol } = useAuth();
  const [usuarios, setUsuarios] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ nombre: '', email: '', clave: '', cargo: '', rol: 2 });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const isAdmin = rol === 'Administrador';

  const load = async () => {
    if (!isAdmin) { setLoading(false); return; }
    try {
      const data = await fetchUsuariosWeb();
      setUsuarios(data);
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const handleCreate = async () => {
    if (!form.nombre || !form.email || !form.clave) {
      setError('Nombre, correo y contraseña son requeridos.'); return;
    }
    setSaving(true); setError('');
    try {
      await registerWebUserApi(form.email, form.nombre, form.clave, form.rol, form.cargo);
      setShowModal(false);
      setForm({ nombre: '', email: '', clave: '', cargo: '', rol: 2 });
      await load();
    } catch (e: any) {
      setError(e.message || 'Error al crear usuario');
    } finally { setSaving(false); }
  };

  const ROL_LABELS: Record<string, string> = {
    Administrador: 'Administrador',
    Supervisor: 'Supervisor',
    Ganadero: 'Ganadero',
  };
  const ROL_STYLES: Record<string, string> = {
    Administrador: 'bg-violet-100 text-violet-800 border border-violet-200',
    Supervisor: 'bg-blue-100 text-blue-800 border border-blue-200',
    Ganadero: 'bg-emerald-100 text-emerald-800 border border-emerald-200',
  };

  if (!isAdmin) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-4">
        <span className="material-symbols-outlined text-slate-300 text-7xl">lock</span>
        <p className="text-slate-500 text-lg font-semibold">Acceso restringido</p>
        <p className="text-slate-400 text-sm">Solo los Administradores pueden ver esta sección.</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5 animate-fade-in">

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <h2 className="text-2xl font-extrabold text-slate-900 flex items-center gap-2" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>
            <span className="material-symbols-outlined text-violet-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>manage_accounts</span>
            Gestión de Usuarios Web
          </h2>
          <p className="text-slate-500 text-sm mt-0.5">
            {loading ? 'Cargando...' : `${usuarios.length} usuario${usuarios.length !== 1 ? 's' : ''} registrado${usuarios.length !== 1 ? 's' : ''} en el portal`}
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-violet-600 hover:bg-violet-700 text-white text-sm font-bold transition-all hover:scale-[1.02] shadow-sm"
        >
          <span className="material-symbols-outlined text-[18px]">person_add</span>
          Nuevo Usuario
        </button>
      </div>

      {/* Tabla */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-xs">
              <th className="py-3 px-4">Usuario</th>
              <th className="py-3 px-4">Correo</th>
              <th className="py-3 px-4">Cargo</th>
              <th className="py-3 px-4 text-center">Rol</th>
              <th className="py-3 px-4 text-center">Fecha Registro</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {loading ? (
              [1,2,3].map(i => (
                <tr key={i}>{[60,40,30,20,20].map((w,j) => (
                  <td key={j} className="py-3 px-4"><div className="skeleton h-4 rounded" style={{ width: `${w}%` }}></div></td>
                ))}</tr>
              ))
            ) : usuarios.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-14 text-center">
                  <span className="material-symbols-outlined text-slate-300 text-5xl block mb-2">people</span>
                  <p className="text-slate-400 italic text-sm">No hay usuarios registrados.</p>
                </td>
              </tr>
            ) : usuarios.map((u: any) => (
              <tr key={u.id} className="hover:bg-violet-50/40 transition-colors">
                <td className="py-3.5 px-4">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-full bg-violet-100 text-violet-800 font-bold flex items-center justify-center text-sm shrink-0">
                      {u.nombre.charAt(0).toUpperCase()}
                    </div>
                    <p className="font-bold text-slate-900">{u.nombre}</p>
                  </div>
                </td>
                <td className="py-3.5 px-4 text-slate-600 font-mono text-xs">{u.email}</td>
                <td className="py-3.5 px-4 text-slate-500">{u.cargo || '—'}</td>
                <td className="py-3.5 px-4 text-center">
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${ROL_STYLES[u.rol] ?? 'bg-slate-100 text-slate-600'}`}>
                    {ROL_LABELS[u.rol] ?? u.rol}
                  </span>
                </td>
                <td className="py-3.5 px-4 text-center text-slate-500 text-xs font-mono">
                  {new Date(u.createdAt).toLocaleDateString('es-NI')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal crear usuario */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm animate-fade-in">
          <div className="bg-white rounded-2xl shadow-2xl border border-slate-200 p-6 w-full max-w-md mx-4 animate-scale-in">
            <div className="flex items-center justify-between mb-5">
              <h3 className="text-xl font-extrabold text-slate-900" style={{ fontFamily: 'Outfit, sans-serif' }}>Nuevo Usuario Web</h3>
              <button onClick={() => { setShowModal(false); setError(''); }}
                className="p-1.5 rounded-lg hover:bg-slate-100 text-slate-500 transition-colors">
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            {error && (
              <div className="mb-4 p-3 rounded-xl bg-rose-50 text-rose-700 text-sm flex items-center gap-2 border border-rose-200">
                <span className="material-symbols-outlined text-[16px]">error</span>{error}
              </div>
            )}

            <div className="space-y-4">
              {[
                { key: 'nombre', label: 'Nombre completo', type: 'text', placeholder: 'Ej. Ana García' },
                { key: 'email', label: 'Correo electrónico', type: 'email', placeholder: 'ana@agrostats.org' },
                { key: 'clave', label: 'Contraseña', type: 'password', placeholder: '••••••••' },
                { key: 'cargo', label: 'Cargo (opcional)', type: 'text', placeholder: 'Ej. Técnico de campo' },
              ].map(field => (
                <div key={field.key}>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">{field.label}</label>
                  <input
                    type={field.type}
                    value={(form as any)[field.key]}
                    onChange={e => setForm(f => ({ ...f, [field.key]: e.target.value }))}
                    placeholder={field.placeholder}
                    className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-violet-500/20 focus:border-violet-500"
                  />
                </div>
              ))}
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Rol</label>
                <select
                  value={form.rol}
                  onChange={e => setForm(f => ({ ...f, rol: parseInt(e.target.value) }))}
                  className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-violet-500/20 focus:border-violet-500"
                >
                  <option value={2}>Supervisor</option>
                  <option value={3}>Administrador</option>
                </select>
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button onClick={() => { setShowModal(false); setError(''); }}
                className="flex-1 py-2.5 rounded-xl border border-slate-200 text-slate-600 font-semibold text-sm hover:bg-slate-50 transition-colors">
                Cancelar
              </button>
              <button onClick={handleCreate} disabled={saving}
                className="flex-1 py-2.5 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-bold text-sm transition-all disabled:opacity-50 flex items-center justify-center gap-2">
                {saving ? <><span className="material-symbols-outlined animate-spin text-[16px]">sync</span>Guardando...</> : 'Crear Usuario'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UsersManagement;
