import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/layout/ProtectedRoute';
import MainLayout from './components/layout/MainLayout';
import Dashboard from './pages/Dashboard';
import FarmMap from './pages/FarmMap';
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
              <Route path="farms" element={<FarmMap />} />
              <Route path="farmers" element={<FarmersManagement />} />
              <Route path="catalogs" element={<CatalogManagement />} />
              <Route path="sync-logs" element={<SyncLogs />} />
            </Route>
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
