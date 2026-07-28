const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://tesis-api-t5zw.onrender.com/api';

// Helper para adjuntar el token automáticamente a todas las peticiones
const fetchWithAuth = async (endpoint: string, options: RequestInit = {}) => {
    const token = localStorage.getItem('agro_token');
    const headers = new Headers(options.headers || {});
    if (token) headers.set('Authorization', `Bearer ${token}`);

    const response = await fetch(`${API_BASE_URL}${endpoint}`, { ...options, headers });

    if (response.status === 401) {
        localStorage.removeItem('agro_token');
        localStorage.removeItem('agro_userid');
        window.location.href = '/login';
        throw new Error('Sesión expirada');
    }

    if (!response.ok) {
        let errorMessage = 'Error en la petición';
        try {
            const errorData = await response.json();
            errorMessage = errorData.error || errorMessage;
        } catch (_) { /* no JSON */ }
        throw new Error(errorMessage);
    }

    return response.json();
};

// ── Autenticación ────────────────────────────────────────────────────────────
export const loginApi = async (email: string, clave: string) => {
    const response = await fetch(`${API_BASE_URL}/web-auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, clave })
    });
    if (!response.ok) {
        let msg = 'Credenciales incorrectas';
        try { msg = (await response.json()).error || msg; } catch (_) {}
        throw new Error(msg);
    }
    return response.json();
};

export const registerWebUserApi = async (email: string, nombre: string, clave: string, rol?: number, cargo?: string) => {
    const token = localStorage.getItem('agro_token');
    const response = await fetch(`${API_BASE_URL}/web-auth/register`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            ...(token ? { 'Authorization': `Bearer ${token}` } : {})
        },
        body: JSON.stringify({ email, nombre, clave, rol, cargo })
    });
    if (!response.ok) {
        let msg = 'Error al registrar usuario';
        try { msg = (await response.json()).error || msg; } catch (_) {}
        throw new Error(msg);
    }
    return response.json();
};

// ── Dashboard ─────────────────────────────────────────────────────────────────
export const fetchKpis = async () =>
    fetchWithAuth('/dashboard/kpis');

export const fetchProduccionTendencia = async () =>
    fetchWithAuth('/dashboard/produccion-tendencia');

export const fetchMapaFincas = async () =>
    fetchWithAuth('/dashboard/mapa-fincas');

// ── Módulo: Detalle de Finca ──────────────────────────────────────────────────
export const fetchFincaDetalle = async (id: string) =>
    fetchWithAuth(`/dashboard/finca/${id}`);

export const fetchRegistrosReproductivosFinca = async (fincaId: string) =>
    fetchWithAuth(`/reproduccion/finca/${fincaId}`);

// ── Módulo: Animales Global ────────────────────────────────────────────────────
export const fetchAnimalesGlobal = async () =>
    fetchWithAuth('/dashboard/animales');

// ── Módulo: Reportes ──────────────────────────────────────────────────────────
export const fetchReportes = async () =>
    fetchWithAuth('/dashboard/reportes');

// ── Módulo: Alertas/Notificaciones ────────────────────────────────────────────
export const fetchAlertas = async () =>
    fetchWithAuth('/dashboard/alertas');

// ── Módulo: Ganaderos ─────────────────────────────────────────────────────────
export const fetchGanaderos = async () =>
    fetchWithAuth('/web-auth/ganaderos');

// ── Módulo: Auditoría Sync ────────────────────────────────────────────────────
export const fetchAuditoriaSync = async () =>
    fetchWithAuth('/web-auth/auditoria-sync');

// ── Módulo: Usuarios Web (Admin only) ─────────────────────────────────────────
export const fetchUsuariosWeb = async () =>
    fetchWithAuth('/web-auth/usuarios-web');

// Cambiar la propia contraseña (usuario autenticado, requiere clave actual)
export const cambiarClaveApi = async (claveActual: string, claveNueva: string) =>
    fetchWithAuth('/web-auth/cambiar-clave', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ claveActual, claveNueva })
    });

// Resetear la contraseña de cualquier usuario web (solo Administrador)
export const resetClaveApi = async (userId: string, claveNueva: string) =>
    fetchWithAuth(`/web-auth/reset-clave/${userId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ claveNueva })
    });

// Resetear la contraseña de un usuario móvil/Ganadero (solo Administrador)
export const resetClaveAppApi = async (userId: string, claveNueva: string) =>
    fetchWithAuth(`/web-auth/reset-clave-app/${userId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ claveNueva })
    });

// ── Catálogos ─────────────────────────────────────────────────────────────────
export const fetchEnfermedades = async () =>
    fetchWithAuth('/catalogos/enfermedades');

export const createEnfermedad = async (enfermedad: any) =>
    fetchWithAuth('/catalogos/enfermedades', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(enfermedad)
    });

export const fetchMedicamentos = async () =>
    fetchWithAuth('/catalogos/medicamentos');

export const createMedicamento = async (medicamento: any) =>
    fetchWithAuth('/catalogos/medicamentos', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(medicamento)
    });

export const fetchRazas = async () =>
    fetchWithAuth('/catalogos/razas');
