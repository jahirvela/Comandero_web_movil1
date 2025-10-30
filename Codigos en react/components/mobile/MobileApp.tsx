import React, { useState } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { NotificationPanel } from './NotificationPanel';
import { 
  ShoppingCart, 
  LogOut,
  Flame,
  Bell,
  CheckCircle
} from 'lucide-react';

import { useNotifications } from './NotificationContext';
import { MeseroIcon } from './RoleSpecificIcons';

// Importar componentes móviles
import { FloorView } from './mobile/FloorView';
import { TableView } from './mobile/TableView';
import { MenuView } from './mobile/MenuView';
import { ProductDetail } from './mobile/ProductDetail';
import { CartView } from './mobile/CartView';

interface User {
  id: string;
  name: string;
  type: 'mesero' | 'cocina' | 'admin' | 'cajero' | 'capitan';
}

interface MobileAppProps {
  user: User;
  onLogout: () => void;
}

export function MobileApp({ user, onLogout }: MobileAppProps) {
  const [currentView, setCurrentView] = useState('floor');
  const [selectedTable, setSelectedTable] = useState(null);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [tableOrders, setTableOrders] = useState({}); // Órdenes por mesa { tableId: [...items] }
  const [showNotifications, setShowNotifications] = useState(false);
  
  const { addNotification, getUnreadCount } = useNotifications();

  const getCurrentCart = () => {
    if (!selectedTable) return [];
    return tableOrders[selectedTable.id] || [];
  };

  const addToCart = (product, customizations = {}) => {
    if (!selectedTable) return;
    
    const cartItem = {
      id: Date.now(),
      ...product,
      customizations,
      tableId: selectedTable.id
    };
    
    setTableOrders(prev => ({
      ...prev,
      [selectedTable.id]: [...(prev[selectedTable.id] || []), cartItem]
    }));
    
    // Agregar notificación cuando se agrega un producto
    addNotification({
      type: 'new_order',
      title: 'Producto Agregado',
      message: `${product.name} agregado a Mesa ${selectedTable?.number}`,
      targetRole: 'cocina',
      fromUser: user.name,
      fromRole: user.type,
      tableNumber: selectedTable?.number,
      priority: 'normal'
    });
  };

  const removeFromCart = (itemId) => {
    if (!selectedTable) return;
    
    setTableOrders(prev => ({
      ...prev,
      [selectedTable.id]: (prev[selectedTable.id] || []).filter(item => item.id !== itemId)
    }));
  };

  const clearCart = () => {
    if (!selectedTable) return;
    
    setTableOrders(prev => ({
      ...prev,
      [selectedTable.id]: []
    }));
  };

  const handleSendToKitchen = (orderData) => {
    const currentCart = getCurrentCart();
    if (currentCart.length === 0) return;

    const isTakeaway = orderData?.isTakeaway || false;
    const orderId = `ORD-${Date.now()}`;

    // Enviar notificación a cocina sobre nuevo pedido
    addNotification({
      type: 'new_order',
      title: isTakeaway ? 'Nuevo Pedido Para Llevar' : 'Nuevo Pedido',
      message: isTakeaway 
        ? `Para llevar - ${orderData.customerName} - ${currentCart.length} productos`
        : `Mesa ${selectedTable?.number} - ${currentCart.length} productos`,
      targetRole: 'cocina',
      fromUser: user.name,
      fromRole: user.type,
      tableNumber: selectedTable?.number,
      orderId: orderId,
      priority: 'normal',
      isTakeaway: isTakeaway,
      customerName: orderData?.customerName || null,
      customerPhone: orderData?.customerPhone || null,
      pickupTime: orderData?.pickupTime || 'Ahora'
    });

    // Limpiar carrito después de enviar
    clearCart();
    
    if (isTakeaway) {
      alert(`Pedido para llevar enviado\nCliente: ${orderData.customerName}`);
    } else {
      alert('¡Pedido enviado a cocina! 🔥');
    }
  };

  const renderView = () => {
    const currentCart = getCurrentCart();
    
    try {
      switch (currentView) {
        case 'floor':
          return (
            <FloorView 
              onTableSelect={(table) => {
                setSelectedTable(table);
                setCurrentView('table');
              }} 
            />
          );
        case 'table':
          return (
            <TableView 
              table={selectedTable}
              onBack={() => setCurrentView('floor')}
              onViewMenu={() => setCurrentView('menu')}
              onViewCart={() => setCurrentView('cart')}
              cart={currentCart}
              user={user}
            />
          );
        case 'menu':
          return (
            <MenuView 
              onBack={() => setCurrentView('table')}
              onProductSelect={(product) => {
                setSelectedProduct(product);
                setCurrentView('product');
              }}
            />
          );
        case 'product':
          return (
            <ProductDetail 
              product={selectedProduct}
              onBack={() => setCurrentView('menu')}
              onAddToCart={addToCart}
            />
          );
        case 'cart':
          return (
            <CartView 
              table={selectedTable}
              items={currentCart}
              onBack={() => setCurrentView('table')}
              onRemoveItem={removeFromCart}
              onClearCart={clearCart}
              onSendToKitchen={handleSendToKitchen}
            />
          );
        default:
          // Fallback seguro - regresar a vista de piso
          setCurrentView('floor');
          return (
            <FloorView onTableSelect={(table) => {
              setSelectedTable(table);
              setCurrentView('table');
            }} />
          );
      }
    } catch (error) {
      // En caso de error, mostrar vista de fallback
      console.error('Error renderizando vista:', error);
      return (
        <div className="flex flex-col items-center justify-center min-h-[400px] text-center space-y-4">
          <div className="text-red-500">
            <Flame className="h-12 w-12 mx-auto mb-2" />
          </div>
          <div>
            <h3 className="text-lg font-medium text-amber-900">Error al cargar vista</h3>
            <p className="text-sm text-amber-700 mb-4">
              Hubo un problema cargando el contenido
            </p>
            <Button 
              onClick={() => {
                setCurrentView('floor');
                setSelectedTable(null);
                setSelectedProduct(null);
              }}
              className="bg-amber-600 hover:bg-amber-700"
            >
              Volver al inicio
            </Button>
          </div>
        </div>
      );
    }
  };

  const unreadCount = getUnreadCount(user.type, user.name);
  const totalCartItems = Object.values(tableOrders).reduce((total, items) => total + items.length, 0);

  return (
    <div className="min-h-screen bg-background">
      {/* Header - Responsivo para todos los tamaños */}
      <header className="bg-gradient-to-r from-amber-600 to-orange-600 text-white px-3 sm:px-4 lg:px-6 py-3 sm:py-4 shadow-md sticky top-0 z-50">
        <div className="flex justify-between items-center max-w-7xl mx-auto">
          <div className="flex items-center gap-2 sm:gap-3 lg:gap-4">
            <MeseroIcon size={32} className="sm:h-10 sm:w-10 lg:h-12 lg:w-12" />
            <div>
              <h1 className="text-sm sm:text-base lg:text-lg font-medium">Comandix</h1>
              <p className="text-xs sm:text-sm lg:text-base text-amber-100">
                {user.name} • Mesero
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-1 sm:gap-2 lg:gap-3">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setShowNotifications(true)}
              className="relative text-white hover:bg-white/20 p-2 sm:p-3 lg:p-4"
            >
              <Bell className="h-4 w-4 sm:h-5 sm:w-5 lg:h-6 lg:w-6" />
              {unreadCount > 0 && (
                <Badge className="absolute -top-1 -right-1 h-4 w-4 sm:h-5 sm:w-5 p-0 flex items-center justify-center text-xs sm:text-sm bg-red-500 text-white border-white">
                  {unreadCount}
                </Badge>
              )}
            </Button>
            
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setCurrentView('cart')}
              className="relative text-white hover:bg-white/20 p-2 sm:p-3 lg:p-4"
            >
              <ShoppingCart className="h-4 w-4 sm:h-5 sm:w-5 lg:h-6 lg:w-6" />
              {totalCartItems > 0 && (
                <Badge className="absolute -top-1 -right-1 h-4 w-4 sm:h-5 sm:w-5 p-0 flex items-center justify-center text-xs sm:text-sm bg-orange-500 text-white border-white">
                  {totalCartItems}
                </Badge>
              )}
            </Button>
            
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={onLogout}
              className="text-white hover:bg-white/20 p-2 sm:p-3 lg:p-4"
            >
              <LogOut className="h-4 w-4 sm:h-5 sm:w-5 lg:h-6 lg:w-6" />
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content - Responsivo con contenedor máximo */}
      <main className="p-3 sm:p-4 lg:p-6 max-w-7xl mx-auto">
        {renderView()}
      </main>

      {/* Panel de Notificaciones */}
      <NotificationPanel
        userRole={user.type}
        userName={user.name}
        isOpen={showNotifications}
        onClose={() => setShowNotifications(false)}
      />

      {/* Estado del puesto - Responsivo */}
      <div className="fixed bottom-4 right-4 sm:bottom-6 sm:right-6 lg:bottom-8 lg:right-8 z-40">
        <div className="bg-gradient-to-r from-green-500 to-green-600 text-white px-3 py-2 sm:px-4 sm:py-3 lg:px-5 lg:py-3 rounded-full shadow-lg flex items-center gap-2 text-sm sm:text-base">
          <CheckCircle className="w-3 h-3 sm:w-4 sm:h-4 lg:w-5 lg:h-5" />
          <span className="hidden sm:inline">Puesto Abierto</span>
          <span className="sm:hidden">Abierto</span>
        </div>
      </div>
    </div>
  );
}