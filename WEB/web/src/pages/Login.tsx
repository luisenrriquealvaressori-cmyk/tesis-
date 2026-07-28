import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { loginApi } from '../services/api';

const Login = () => {
  const [email, setEmail] = useState('');
  const [clave, setClave] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [emailError, setEmailError] = useState('');
  const [claveError, setClaveError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const validate = () => {
    let valid = true;
    setEmailError('');
    setClaveError('');

    if (!email) {
      setEmailError('El correo electrónico es requerido.');
      valid = false;
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setEmailError('Ingresa un correo electrónico válido.');
      valid = false;
    }
    if (!clave) {
      setClaveError('La contraseña es requerida.');
      valid = false;
    } else if (clave.length < 6) {
      setClaveError('La contraseña debe tener al menos 6 caracteres.');
      valid = false;
    }
    return valid;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!validate()) return;

    setIsLoading(true);
    try {
      const data = await loginApi(email, clave);
      login(data.token, data.usuarioId, data.nombre, data.rol);
      setSuccess(true);
      setTimeout(() => navigate('/'), 800);
    } catch (err: any) {
      setError(err.message || 'Credenciales incorrectas. Verifica tu correo y contraseña.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden">
      {/* Background */}
      <div 
        className="absolute inset-0 z-0 bg-cover bg-center"
        style={{ backgroundImage: "url('https://images.unsplash.com/photo-1590402237895-e23f03b60dc4?q=80&w=2070&auto=format&fit=crop')" }}
      >
        <div className="absolute inset-0 bg-gradient-to-br from-[#012d1d]/80 via-black/50 to-[#012d1d]/70 backdrop-blur-[3px]"></div>
      </div>

      {/* Decorative orbs */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none"></div>
      <div className="absolute bottom-1/4 right-1/4 w-64 h-64 bg-teal-400/10 rounded-full blur-2xl pointer-events-none"></div>

      {/* Card */}
      <div className="relative z-10 w-full max-w-md mx-4 p-8 bg-white/10 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/20 animate-scale-in">
        
        {/* Logo + Title */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-400 to-teal-600 mb-4 shadow-lg shadow-emerald-900/40">
            <span className="material-symbols-outlined text-white" style={{ fontSize: '30px', fontVariationSettings: "'FILL' 1" }}>agriculture</span>
          </div>
          <h1 className="text-3xl font-extrabold text-white tracking-tight" style={{ fontFamily: 'Outfit, Inter, sans-serif' }}>AgroControl</h1>
          <p className="text-emerald-100/70 text-sm mt-1 font-medium">Portal de Supervisión Institucional</p>
          <div className="inline-flex items-center gap-2 mt-2 px-3 py-1 rounded-full bg-emerald-500/20 border border-emerald-400/30">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
            <span className="text-emerald-300 text-xs font-semibold">Sistema en línea</span>
          </div>
        </div>

        {/* General error */}
        {error && (
          <div className="mb-5 p-3.5 rounded-xl bg-rose-500/20 text-rose-200 text-sm flex items-center gap-2 border border-rose-400/30 animate-slide-up">
            <span className="material-symbols-outlined text-rose-300 shrink-0" style={{ fontSize: '18px' }}>error</span>
            {error}
          </div>
        )}

        {/* Success indicator */}
        {success && (
          <div className="mb-5 p-3.5 rounded-xl bg-emerald-500/20 text-emerald-200 text-sm flex items-center gap-2 border border-emerald-400/30 animate-scale-in">
            <span className="material-symbols-outlined text-emerald-300 shrink-0" style={{ fontSize: '18px', fontVariationSettings: "'FILL' 1" }}>check_circle</span>
            Acceso verificado. Redirigiendo...
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Email */}
          <div>
            <label className="block text-sm font-semibold text-white/90 mb-1.5" htmlFor="email">
              Correo electrónico
            </label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-emerald-300/70">
                <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>mail</span>
              </span>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => { setEmail(e.target.value); setEmailError(''); }}
                className={`w-full pl-10 pr-4 py-3 bg-white/10 border rounded-xl text-white placeholder-white/30 text-sm transition-all focus:outline-none focus:bg-white/15 ${emailError ? 'border-rose-400/70 focus:border-rose-400' : 'border-white/20 focus:border-emerald-400/70'}`}
                style={{ backdropFilter: 'blur(8px)' }}
                placeholder="admin@ganadero.com"
                required
                autoComplete="email"
              />
            </div>
            {emailError && <p className="mt-1.5 text-rose-300 text-xs flex items-center gap-1"><span className="material-symbols-outlined" style={{ fontSize: '14px' }}>error</span>{emailError}</p>}
          </div>

          {/* Password */}
          <div>
            <label className="block text-sm font-semibold text-white/90 mb-1.5" htmlFor="clave">
              Contraseña
            </label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-emerald-300/70">
                <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>lock</span>
              </span>
              <input
                id="clave"
                type={showPassword ? 'text' : 'password'}
                value={clave}
                onChange={(e) => { setClave(e.target.value); setClaveError(''); }}
                className={`w-full pl-10 pr-11 py-3 bg-white/10 border rounded-xl text-white placeholder-white/30 text-sm transition-all focus:outline-none focus:bg-white/15 ${claveError ? 'border-rose-400/70 focus:border-rose-400' : 'border-white/20 focus:border-emerald-400/70'}`}
                style={{ backdropFilter: 'blur(8px)' }}
                placeholder="••••••••"
                required
                autoComplete="current-password"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute inset-y-0 right-0 flex items-center pr-3.5 text-emerald-300/60 hover:text-emerald-300 transition-colors"
                tabIndex={-1}
              >
                <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>
                  {showPassword ? 'visibility_off' : 'visibility'}
                </span>
              </button>
            </div>
            {claveError && <p className="mt-1.5 text-rose-300 text-xs flex items-center gap-1"><span className="material-symbols-outlined" style={{ fontSize: '14px' }}>error</span>{claveError}</p>}
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={isLoading || success}
            className="w-full flex items-center justify-center py-3.5 px-4 rounded-2xl font-bold text-white bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-600 hover:to-teal-700 shadow-lg shadow-emerald-900/30 transition-all duration-200 hover:scale-[1.02] active:scale-[0.98] disabled:opacity-60 disabled:cursor-not-allowed disabled:scale-100"
          >
            {isLoading ? (
              <span className="flex items-center gap-2">
                <span className="material-symbols-outlined animate-spin" style={{ fontSize: '20px' }}>sync</span>
                Verificando acceso...
              </span>
            ) : success ? (
              <span className="flex items-center gap-2">
                <span className="material-symbols-outlined" style={{ fontSize: '20px', fontVariationSettings: "'FILL' 1" }}>check_circle</span>
                Acceso concedido
              </span>
            ) : (
              <span className="flex items-center gap-2">
                Ingresar al Portal
                <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>arrow_forward</span>
              </span>
            )}
          </button>
        </form>

        {/* Footer */}
        <p className="text-center text-white/30 text-xs mt-6 font-mono">
          AgroControl v1.0 · Plataforma Institucional
        </p>
      </div>
    </div>
  );
};

export default Login;
