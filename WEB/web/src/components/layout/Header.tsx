const Header = () => {
  return (
    <header className="flex justify-between items-center w-full h-16 px-gutter max-w-container-max-width ml-auto bg-surface border-b border-outline-variant z-40 shrink-0">
      <div className="flex items-center gap-md">
        <button className="md:hidden p-sm text-on-surface-variant hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined">menu</span>
        </button>
        <h1 className="md:hidden font-headline-lg-mobile text-headline-lg-mobile font-black text-primary ml-sm">AgroControl</h1>
        
        <div className="hidden md:flex items-center bg-surface-container-low border border-outline-variant rounded-lg px-md h-10 w-96 input-focus transition-all">
          <span className="material-symbols-outlined text-outline mr-sm">search</span>
          <input className="bg-transparent border-none outline-none focus:ring-0 w-full font-body-md text-body-md text-on-surface placeholder-outline p-0" placeholder="Buscar fincas, catálogos, dueños..." type="text" />
        </div>
      </div>
      
      <div className="flex items-center gap-lg ml-auto">
        <button className="text-on-surface-variant hover:bg-surface-container-low transition-colors p-2 rounded-full relative">
          <span className="material-symbols-outlined">notifications</span>
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-error rounded-full"></span>
        </button>
        <img alt="Administrator Profile" className="w-8 h-8 rounded-full object-cover border border-outline-variant md:hidden" src="https://lh3.googleusercontent.com/aida-public/AB6AXuB_MUOVLXQGIlqpUpyCYIIchtWr7HRGiGj7afVNFm3kR55hzB_XUQAvXmrO_9ZzepcMW91bjALpNCv0C2AiO7-emGIsGASI4bTwXWUKkcV-JxfzyIn6UOk4xHc4vAaLGA4vhrylcRtI5yy6FpVyjeff2HfQfULT6MZdGRGH3idMqBVOIDX5vmR3u1EDB0n9N6xk6v8lAeSq3GCC-U2jRbO42zRho4RtUY_U7xbzoGeVM4wUKlRnw4mgw8Im_BvAxFnjyORe2rtrCXIN" />
      </div>
    </header>
  );
};

export default Header;
