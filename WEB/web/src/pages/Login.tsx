import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { loginApi } from '../services/api';

const Login = () => {
  const [email, setEmail] = useState('');
  const [clave, setClave] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      const data = await loginApi(email, clave);
      login(data.token, data.usuarioId, data.nombre, data.rol);
      navigate('/');
    } catch (err: any) {
      setError(err.message || 'Credenciales incorrectas');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-[#e5e5e5]">
      {/* Background Image & Overlay */}
      <div 
        className="absolute inset-0 z-0 bg-cover bg-center"
        style={{ backgroundImage: "url('https://images.unsplash.com/photo-1590402237895-e23f03b60dc4?q=80&w=2070&auto=format&fit=crop')" }}
      >
        <div className="absolute inset-0 bg-black/40 backdrop-blur-[2px]"></div>
      </div>

      <div className="relative z-10 w-full max-w-md p-8 bg-surface-container-lowest/90 backdrop-blur-md rounded-2xl shadow-2xl border border-outline-variant/30 transform transition-all">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary-container text-on-primary-container mb-4 shadow-sm">
            <span className="material-symbols-outlined" style={{ fontSize: '32px' }}>landscape</span>
          </div>
          <h1 className="text-headline-lg font-bold text-primary">AgroStats</h1>
          <p className="text-body-lg text-on-surface-variant mt-2">Portal de Supervisión</p>
        </div>

        {error && (
          <div className="mb-6 p-4 rounded-lg bg-error-container/80 text-on-error-container text-sm flex items-center gap-2 border border-error/20">
            <span className="material-symbols-outlined text-error" style={{ fontSize: '20px' }}>error</span>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-label-lg font-medium text-on-surface mb-2" htmlFor="email">
              Correo electrónico
            </label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-on-surface-variant">
                <span className="material-symbols-outlined" style={{ fontSize: '20px' }}>mail</span>
              </span>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-10 pr-4 py-3 bg-surface border border-outline-variant rounded-lg focus:ring-2 focus:ring-primary focus:border-primary transition-shadow text-on-surface"
                placeholder="admin@ganadero.com"
                required
                autoComplete="email"
              />
            </div>
          </div>

          <div>
            <label className="block text-label-lg font-medium text-on-surface mb-2" htmlFor="clave">
              Contraseña
            </label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-on-surface-variant">
                <span className="material-symbols-outlined" style={{ fontSize: '20px' }}>lock</span>
              </span>
              <input
                id="clave"
                type="password"
                value={clave}
                onChange={(e) => setClave(e.target.value)}
                className="w-full pl-10 pr-4 py-3 bg-surface border border-outline-variant rounded-lg focus:ring-2 focus:ring-primary focus:border-primary transition-shadow text-on-surface"
                placeholder="••••••••"
                required
                autoComplete="current-password"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full flex items-center justify-center py-3 px-4 border border-transparent rounded-full shadow-sm text-label-lg font-medium text-on-primary bg-primary hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-colors disabled:opacity-70 disabled:cursor-not-allowed"
          >
            {isLoading ? (
              <span className="flex items-center gap-2">
                <span className="material-symbols-outlined animate-spin" style={{ fontSize: '20px' }}>sync</span>
                Iniciando sesión...
              </span>
            ) : (
              'Ingresar al Portal'
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

export default Login;
