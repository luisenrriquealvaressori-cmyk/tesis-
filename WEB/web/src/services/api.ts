const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://tesis-api-t5zw.onrender.com/api';

// Helper para adjuntar el token automáticamente a todas las peticiones
const fetchWithAuth = async (endpoint: string, options: RequestInit = {}) => {
    const token = localStorage.getItem('agro_token');
    
    const headers = new Headers(options.headers || {});
    if (token) {
        headers.set('Authorization', `Bearer ${token}`);
    }
    
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        ...options,
        headers
    });
    
    if (response.status === 401) {
        // Token expirado o inválido
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
        } catch (e) {
            // No JSON error response
        }
        throw new Error(errorMessage);
    }
    
    return response.json();
};

export const loginApi = async (telefono: string, clave: string) => {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ telefono, clave })
    });
    
    if (!response.ok) {
        let errorMessage = 'Credenciales incorrectas';
        try {
            const errorData = await response.json();
            errorMessage = errorData.error || errorMessage;
        } catch (e) {}
        throw new Error(errorMessage);
    }
    return response.json();
};

export const fetchKpis = async () => {
    return fetchWithAuth('/dashboard/kpis');
};

export const fetchMapaFincas = async () => {
    return fetchWithAuth('/dashboard/mapa-fincas');
};

export const fetchEnfermedades = async () => {
    return fetchWithAuth('/catalogos/enfermedades');
};

export const createEnfermedad = async (enfermedad: any) => {
    return fetchWithAuth('/catalogos/enfermedades', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(enfermedad)
    });
};
