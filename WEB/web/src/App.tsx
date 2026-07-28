import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/layout/ProtectedRoute';
import MainLayout from './components/layout/MainLayout';
import Dashboard from './pages/Dashboard';
import FarmMap from './pages/FarmMap';
import FarmDetail from './pages/FarmDetail';
import AnimalesPanel from './pages/AnimalesPanel';
import ReportsPage from './pages/ReportsPage';
import UsersManagement from './pages/UsersManagement';
import CatalogManagement from './pages/CatalogManagement';
import FarmersManagement from './pages/FarmersManagement';
import SyncLogs from './pages/SyncLogs';
import Login from './pages/Login';

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<MainLayout />}>
              <Route index element={<Dashboard />} />
              {/* Fincas */}
              <Route path="farms" element={<FarmMap />} />
              <Route path="farms/:id" element={<FarmDetail />} />
              {/* Animales */}
              <Route path="animals" element={<AnimalesPanel />} />
              {/* Ganaderos */}
              <Route path="farmers" element={<FarmersManagement />} />
              {/* Reportes */}
              <Route path="reports" element={<ReportsPage />} />
              {/* Catálogos */}
              <Route path="catalogs" element={<CatalogManagement />} />
              {/* Auditoría Sync */}
              <Route path="sync-logs" element={<SyncLogs />} />
              {/* Usuarios web (Admin only) */}
              <Route path="settings/users" element={<UsersManagement />} />
            </Route>
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
