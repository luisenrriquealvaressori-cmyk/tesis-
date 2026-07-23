import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';

const MainLayout = () => {
  return (
    <div className="bg-background text-on-background font-body-md text-body-md antialiased overflow-hidden flex h-screen w-screen">
      <Sidebar />
      <div className="flex-1 flex flex-col md:ml-sidebar-width h-full w-full relative">
        <Header />
        <main className="flex-1 overflow-auto flex flex-col p-md md:p-gutter max-w-container-max-width mx-auto w-full gap-gutter">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default MainLayout;
