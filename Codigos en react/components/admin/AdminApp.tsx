import React, { useState } from 'react';
import { Button } from '@ui/button';
import { Dashboard } from './Dashboard';
import { TableManagement } from './TableManagement';
import { MenuManagement } from './MenuManagement';
import { Inventory } from './Inventory';
import { NewCashClose } from './NewCashClose';
import { CashierClosureManagement } from './CashierClosureManagement';
import { TicketManagement } from './TicketManagement';
import { UserManagement } from './UserManagement';
import { KitchenApp } from '@components/kitchen/KitchenApp';
import { 
  ChefHat, 
  Calculator,
  LogOut,
  Menu as MenuIcon,
  Receipt,
  Monitor,
  Settings,
  UserCheck,
  Box,
  Users
} from 'lucide-react';
import { Sheet, SheetContent, SheetTrigger, SheetTitle, SheetDescription, SheetHeader } from '@ui/sheet';
import { LogoC } from '@components/shared/RoleSpecificIcons';

const menuItems = [
  { id: 'dashboard', name: 'Panel de Control', icon: Settings },
  { id: 'tables', name: 'Gestión de Mesas', icon: UserCheck },
  { id: 'menu', name: 'Gestión de Menú', icon: ChefHat },
  { id: 'inventory', name: 'Inventario', icon: Box },
  { id: 'users', name: 'Gestión de Usuarios', icon: Users },
  { id: 'kds', name: 'Filtros de Cocina', icon: ChefHat },
  { id: 'tickets', name: 'Gestión de Tickets', icon: Receipt }
];

const cashMenuItems = [
  { id: 'cash-overview', name: 'Vista General', icon: Monitor },
  { id: 'cash-review', name: 'Revisar Cierres de Cajeros', icon: UserCheck }
];

interface User {
  id: string;
  name: string;
  type: 'mesero' | 'cocina' | 'admin' | 'cajero' | 'capitan';
}

interface AdminAppProps {
  user: User;
  onLogout: () => void;
}

export function AdminApp({ user, onLogout }: AdminAppProps) {
  const [currentView, setCurrentView] = useState('dashboard');
  const [currentCashView, setCurrentCashView] = useState('cash-overview');
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [cashMenuOpen, setCashMenuOpen] = useState(false);

  const renderView = () => {
    switch (currentView) {
      case 'dashboard':
        return <Dashboard />;
      case 'tables':
        return <TableManagement />;
      case 'menu':
        return <MenuManagement />;
      case 'inventory':
        return <Inventory />;
      case 'users':
        return <UserManagement />;
      case 'kds':
        return <KitchenApp user={user} onLogout={onLogout} />;
      case 'cash':
        return renderCashView();
      case 'tickets':
        return <TicketManagement />;
      default:
        return <Dashboard />;
    }
  };

  const renderCashView = () => {
    switch (currentCashView) {
      case 'cash-overview':
        return <NewCashClose userRole="admin" />;
      case 'cash-review':
        return <CashierClosureManagement userRole="admin" />;
      default:
        return <NewCashClose userRole="admin" />;
    }
  };

  const SidebarContent = () => (
    <div className="flex flex-col h-full bg-amber-50">
      {/* Logo y usuario - Responsivo */}
      <div className="p-4 lg:p-6 border-b border-amber-200">
        <div className="flex items-center gap-3 mb-4">
          <Settings className="h-8 w-8 lg:h-10 lg:w-10 text-amber-600" />
          <div>
            <h2 className="font-medium lg:text-lg text-amber-900 font-bold">Comandix Admin</h2>
            <p className="text-sm lg:text-base text-amber-700">Panel de Control</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <LogoC size={32} className="lg:h-10 lg:w-10" />
          <div className="text-sm lg:text-base">
            <p className="font-medium text-amber-900">{user.name}</p>
            <p className="text-amber-700">Administrador</p>
          </div>
        </div>
      </div>

      {/* Navegación - Responsivo */}
      <nav className="flex-1 p-3 lg:p-4">
        <div className="space-y-1 lg:space-y-2">
          {menuItems.map(item => {
            const IconComponent = item.icon;
            return (
              <div key={item.id}>
                <Button
                  variant={currentView === item.id ? "default" : "ghost"}
                  className={`w-full justify-start text-sm lg:text-base py-2 lg:py-3 ${
                    currentView === item.id 
                      ? "bg-amber-600 text-white hover:bg-amber-700" 
                      : "text-amber-900 hover:bg-amber-100"
                  }`}
                  onClick={() => {
                    setCurrentView(item.id);
                    setSidebarOpen(false);
                  }}
                >
                  <IconComponent className="h-4 w-4 lg:h-5 lg:w-5 mr-3" />
                  {item.name}
                </Button>
              </div>
            );
          })}
          
          {/* Sección de Cierre de Caja con sub-menú */}
          <div className="space-y-1">
            <Button
              variant={currentView === 'cash' ? "default" : "ghost"}
              className={`w-full justify-start text-sm lg:text-base py-2 lg:py-3 ${
                currentView === 'cash' 
                  ? "bg-amber-600 text-white hover:bg-amber-700" 
                  : "text-amber-900 hover:bg-amber-100"
              }`}
              onClick={() => {
                setCurrentView('cash');
                setCashMenuOpen(!cashMenuOpen);
              }}
            >
              <Calculator className="h-4 w-4 lg:h-5 lg:w-5 mr-3" />
              Cierre de Caja
            </Button>
            
            {/* Sub-menú de Cierre de Caja */}
            {currentView === 'cash' && (
              <div className="ml-4 space-y-1">
                {cashMenuItems.map(subItem => {
                  const SubIconComponent = subItem.icon;
                  return (
                    <Button
                      key={subItem.id}
                      variant={currentCashView === subItem.id ? "secondary" : "ghost"}
                      size="sm"
                      className={`w-full justify-start text-sm ${
                        currentCashView === subItem.id 
                          ? "bg-amber-200 text-amber-900 hover:bg-amber-300" 
                          : "text-amber-700 hover:bg-amber-100"
                      }`}
                      onClick={() => {
                        setCurrentCashView(subItem.id);
                        setSidebarOpen(false);
                      }}
                    >
                      <SubIconComponent className="h-3 w-3 mr-2" />
                      {subItem.name}
                    </Button>
                  );
                })}
              </div>
            )}
          </div>
          
          {/* Logout */}
          <div className="mt-3 pt-3 border-t border-amber-200">
            <Button 
              variant="ghost" 
              onClick={onLogout}
              className="w-full justify-start text-sm lg:text-base py-2 lg:py-3 text-red-600 hover:text-red-700 hover:bg-red-50"
            >
              <LogOut className="h-4 w-4 lg:h-5 lg:w-5 mr-3" />
              Cerrar Sesión
            </Button>
          </div>
        </div>
      </nav>
    </div>
  );

  return (
    <div className="min-h-screen bg-background">
      {/* Desktop Layout - Mejorado para XL */}
      <div className="hidden lg:flex">
        {/* Sidebar fijo en desktop */}
        <div className="w-64 xl:w-72 bg-amber-50 border-r border-amber-200">
          <SidebarContent />
        </div>
        
        {/* Contenido principal */}
        <div className="flex-1 overflow-x-hidden">
          <main className="p-6 xl:p-8 max-w-7xl mx-auto">
            {renderView()}
          </main>
        </div>
      </div>

      {/* Tablet Layout - Nuevo */}
      <div className="hidden md:block lg:hidden">
        <header className="bg-gradient-to-r from-amber-600 to-orange-600 text-white px-4 py-4 flex justify-between items-center shadow-md sticky top-0 z-50">
          <div className="flex items-center gap-4">
            <LogoC size={40} />
            <div>
              <h1 className="text-base font-medium font-bold">Comandix Admin</h1>
              <p className="text-sm text-amber-100">
                {currentView === 'cash' 
                  ? `Cierre de Caja — ${cashMenuItems.find(item => item.id === currentCashView)?.name}`
                  : menuItems.find(item => item.id === currentView)?.name
                }
              </p>
            </div>
          </div>
          
          <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}>
            <SheetTrigger asChild>
              <Button variant="ghost" size="sm" className="text-white hover:bg-white/20 p-3">
                <MenuIcon className="h-5 w-5" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="p-0 w-72">
              <SheetHeader className="sr-only">
                <SheetTitle>Menú de navegación</SheetTitle>
                <SheetDescription>
                  Opciones de navegación para el panel de administración
                </SheetDescription>
              </SheetHeader>
              <SidebarContent />
            </SheetContent>
          </Sheet>
        </header>

        <main className="p-4 max-w-6xl mx-auto">
          {renderView()}
        </main>
      </div>

      {/* Mobile Layout - Mejorado */}
      <div className="md:hidden">
        {/* Header móvil */}
        <header className="bg-gradient-to-r from-amber-600 to-orange-600 text-white px-3 py-3 flex justify-between items-center shadow-md sticky top-0 z-50">
          <div className="flex items-center gap-3">
            <LogoC size={32} />
            <div>
              <h1 className="text-sm font-medium font-bold">Comandix Admin</h1>
              <p className="text-xs text-amber-100">
                {currentView === 'cash' 
                  ? `Cierre de Caja — ${cashMenuItems.find(item => item.id === currentCashView)?.name}`
                  : menuItems.find(item => item.id === currentView)?.name
                }
              </p>
            </div>
          </div>
          
          <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}>
            <SheetTrigger asChild>
              <Button variant="ghost" size="sm" className="text-white hover:bg-white/20">
                <MenuIcon className="h-4 w-4" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="p-0 w-64">
              <SheetHeader className="sr-only">
                <SheetTitle>Menú de navegación</SheetTitle>
                <SheetDescription>
                  Opciones de navegación para el panel de administración
                </SheetDescription>
              </SheetHeader>
              <SidebarContent />
            </SheetContent>
          </Sheet>
        </header>

        {/* Contenido principal móvil */}
        <main className="p-3">
          {renderView()}
        </main>
      </div>
    </div>
  );
}