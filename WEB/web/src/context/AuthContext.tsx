import { createContext, useContext, useState, useEffect, type ReactNode } from 'react';

interface AuthContextType {
  token: string | null;
  usuarioId: string | null;
  nombre: string | null;
  rol: string | null;
  login: (token: string, usuarioId: string, nombre: string, rol?: string) => void;
  logout: () => void;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [token, setToken] = useState<string | null>(null);
  const [usuarioId, setUsuarioId] = useState<string | null>(null);
  const [nombre, setNombre] = useState<string | null>(null);
  const [rol, setRol] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Restaurar sesión desde localStorage
    const savedToken = localStorage.getItem('agro_token');
    const savedUserId = localStorage.getItem('agro_userid');
    const savedNombre = localStorage.getItem('agro_nombre');
    const savedRol = localStorage.getItem('agro_rol');

    if (savedToken) {
      setToken(savedToken);
      setUsuarioId(savedUserId);
      setNombre(savedNombre);
      setRol(savedRol);
    }
    setLoading(false);
  }, []);

  const login = (newToken: string, newUsuarioId: string, newNombre: string, newRol: string = 'Supervisor') => {
    localStorage.setItem('agro_token', newToken);
    localStorage.setItem('agro_userid', newUsuarioId);
    localStorage.setItem('agro_nombre', newNombre);
    localStorage.setItem('agro_rol', newRol);
    setToken(newToken);
    setUsuarioId(newUsuarioId);
    setNombre(newNombre);
    setRol(newRol);
  };

  const logout = () => {
    localStorage.removeItem('agro_token');
    localStorage.removeItem('agro_userid');
    localStorage.removeItem('agro_nombre');
    localStorage.removeItem('agro_rol');
    setToken(null);
    setUsuarioId(null);
    setNombre(null);
    setRol(null);
  };

  if (loading) return <div className="h-screen w-screen flex items-center justify-center">Cargando...</div>;

  return (
    <AuthContext.Provider value={{ token, usuarioId, nombre, rol, login, logout, isAuthenticated: !!token }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
