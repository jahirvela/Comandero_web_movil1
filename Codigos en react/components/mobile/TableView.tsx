import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from '../ui/dialog';
import { ArrowLeft, Users, ShoppingCart, Receipt, Plus, Flame, Clock, ChefHat, Trash2, AlertTriangle, DollarSign, Send, Calculator } from 'lucide-react';
import { toast } from 'sonner@2.0.3';
import { AlertToKitchenModal } from '../AlertToKitchenModal';

import { CerrarCuentaModal } from '../CerrarCuentaModal';

const getStatusColor = (status) => {
  switch (status) {
    case 'libre': return 'bg-green-100 text-green-800 border-green-300';
    case 'ocupada': return 'bg-red-100 text-red-800 border-red-300';
    case 'en-limpieza': return 'bg-gray-100 text-gray-800 border-gray-300';
    case 'reservada': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    default: return 'bg-gray-100 text-gray-800 border-gray-300';
  }
};

const getStatusText = (status) => {
  switch (status) {
    case 'libre': return 'Libre';
    case 'ocupada': return 'Ocupada';
    case 'en-limpieza': return 'En Limpieza';
    case 'reservada': return 'Reservada';
    default: return 'Desconocido';
  }
};

export function TableView({ table, onBack, onViewMenu, onViewCart, cart, user }) {
  const [customers, setCustomers] = useState(table.customers || 0);
  const [isEditing, setIsEditing] = useState(false);
  const [showClearDialog, setShowClearDialog] = useState(false);
  const [showRestoreDemo, setShowRestoreDemo] = useState(false);
  const [showAlertModal, setShowAlertModal] = useState(false);

  const [showCerrarCuentaModal, setShowCerrarCuentaModal] = useState(false);

  // Mock de historial original para poder restaurar en demo
  const originalOrderHistory = [
    {
      id: 'ORD-034',
      items: ['3x Taco Barbacoa'],
      status: 'Listo',
      time: '14:20'
    },
    {
      id: 'ORD-029',
      items: ['1x Mix Barbacoa', '2x Agua Horchata'],
      status: 'En preparación',
      time: '13:45'
    },
    {
      id: 'ORD-025',
      items: ['2x Quesadilla Barbacoa'],
      status: 'Entregado',
      time: '13:15'
    },
    {
      id: 'ORD-021',
      items: ['4x Taco Carnitas', '1x Consomé Grande'],
      status: 'Entregado',
      time: '12:50'
    },
    {
      id: 'ORD-018',
      items: ['2x Taco Barbacoa'],
      status: 'Entregado',
      time: '12:30'
    },
    {
      id: 'ORD-015',
      items: ['1x Quesadilla Barbacoa'],
      status: 'Cancelado',
      time: '12:15'
    }
  ];

  // Estado de historial de pedidos para la mesa
  const [orderHistory, setOrderHistory] = useState(originalOrderHistory);

  const getOrderStatusColor = (status) => {
    switch (status) {
      case 'En cocina': return 'bg-orange-100 text-orange-800 border-orange-300';
      case 'En preparación': return 'bg-blue-100 text-blue-800 border-blue-300';
      case 'Listo': return 'bg-green-100 text-green-800 border-green-300';
      case 'Entregado': return 'bg-gray-100 text-gray-800 border-gray-300';
      case 'Cancelado': return 'bg-red-100 text-red-800 border-red-300';
      case 'Enviado al Cajero': return 'bg-blue-100 text-blue-800 border-blue-300';
      default: return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const calculateTotal = () => {
    return cart.reduce((total, item) => total + item.price, 0);
  };

  const handleClearHistory = () => {
    setOrderHistory([]);
    setShowRestoreDemo(true);
    setShowClearDialog(false);
    toast.success(`Historial de la Mesa ${table.number} limpiado`);
  };

  const handleRestoreDemo = () => {
    setOrderHistory(originalOrderHistory);
    setShowRestoreDemo(false);
    toast.success('Datos demo restaurados');
  };

  // Preparar resumen completo de TODO el consumo de la mesa (historial + carrito)
  const prepareOrderSummary = () => {
    const summary = {};
    
    // Agregar items del historial de pedidos entregados
    orderHistory.forEach(order => {
      if (order.status === 'Entregado' || order.status === 'Listo') {
        order.items.forEach(itemStr => {
          // Parsear strings como "3x Taco Barbacoa" 
          const match = itemStr.match(/^(\d+)x\s(.+)$/);
          if (match) {
            const quantity = parseInt(match[1]);
            const name = match[2];
            const key = name;
            
            if (summary[key]) {
              summary[key].quantity += quantity;
            } else {
              summary[key] = {
                id: `history-${Date.now()}-${Math.random()}`,
                name: name,
                quantity: quantity,
                price: getItemPrice(name), // Función helper para obtener precio
                extras: [],
                customizations: {}
              };
            }
          }
        });
      }
    });
    
    // Agregar items del carrito actual
    cart.forEach(item => {
      const key = item.name;
      if (summary[key]) {
        summary[key].quantity += 1;
      } else {
        summary[key] = {
          id: item.id || `cart-${Date.now()}`,
          name: item.name,
          quantity: 1,
          price: item.price,
          extras: item.extras || [],
          customizations: item.customizations || {}
        };
      }
    });
    
    return Object.values(summary);
  };

  // Helper para obtener precios de items del historial
  const getItemPrice = (itemName) => {
    // Precios base del menú - esto debería venir del contexto del menú
    const menuPrices = {
      'Taco Barbacoa': 22,
      'Taco Carnitas': 22, 
      'Mix Barbacoa': 95,
      'Quesadilla Barbacoa': 40,
      'Consomé Grande': 35,
      'Consomé Mediano': 25,
      'Agua Horchata': 18,
      'Refresco': 12
    };
    
    return menuPrices[itemName] || 20; // Precio por defecto si no se encuentra
  };

  const handleAccountSent = (accountData) => {
    // Añadir entrada al historial indicando que se envió la cuenta
    const newHistoryEntry = {
      id: accountData.id,
      items: [`Cuenta enviada por ${user.name}`],
      status: 'Enviado al Cajero',
      time: accountData.timestamp
    };
    
    setOrderHistory(prev => [newHistoryEntry, ...prev]);
    
    // Limpiar el carrito después de enviar la cuenta
    // Esto simula que la cuenta ya se procesó y no debería seguir en consumo
  };

  // El botón Cerrar cuenta debe aparecer siempre si hay historial de pedidos
  const hasItemsForBilling = orderHistory.length > 0;

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Columna principal - Información de la mesa y consumo */}
      <div className="lg:col-span-2 space-y-6">
        {/* Header */}
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" onClick={onBack} className="text-amber-700 hover:bg-amber-100">
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h2 className="text-xl font-medium text-amber-900">Mesa {table.number}</h2>
            <p className="text-sm text-amber-700">{table.seats} lugares disponibles</p>
          </div>
        </div>

        {/* Estado de la mesa */}
        <Card className="border-amber-200">
          <CardHeader>
            <CardTitle className="flex items-center justify-between text-amber-900">
              <span>Estado de la Mesa</span>
              <Badge className={getStatusColor(table.status)}>
                {getStatusText(table.status)}
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Comensales */}
            <div className="flex items-center justify-between">
              <Label htmlFor="customers" className="flex items-center gap-2 text-amber-900">
                <Users className="h-4 w-4" />
                Comensales
              </Label>
              {isEditing ? (
                <div className="flex items-center gap-2">
                  <Input
                    id="customers"
                    type="number"
                    value={customers}
                    onChange={(e) => setCustomers(parseInt(e.target.value) || 0)}
                    className="w-20 border-amber-200 focus:border-amber-500"
                    min="0"
                    max={table.seats}
                  />
                  <Button 
                    size="sm" 
                    onClick={() => setIsEditing(false)}
                    className="bg-amber-600 hover:bg-amber-700"
                  >
                    OK
                  </Button>
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <span className="text-amber-900">{customers} personas</span>
                  <Button 
                    variant="ghost" 
                    size="sm"
                    onClick={() => setIsEditing(true)}
                    className="text-amber-700 hover:bg-amber-100"
                  >
                    Editar
                  </Button>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Consumo de Mesa */}
        <Card className="border-amber-200">
          <CardHeader>
            <CardTitle className="flex items-center justify-between text-amber-900">
              <span>Consumo de Mesa</span>
              <Badge variant="outline" className="border-amber-300 text-amber-800">
                {cart.length} {cart.length === 1 ? 'artículo' : 'artículos'}
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            {cart.length === 0 ? (
              <div className="text-center py-6 text-amber-700">
                <ShoppingCart className="h-12 w-12 mx-auto mb-2 opacity-50" />
                <p>No hay artículos en el consumo</p>
                <p className="text-sm">Toca "Agregar Productos" para comenzar</p>
              </div>
            ) : (
              <div className="space-y-3">
                {cart.slice(0, 3).map((item, index) => (
                  <div key={index} className="flex justify-between items-center p-3 bg-amber-50 rounded border border-amber-200">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-amber-900">{item.name}</span>
                        {item.hot && <Flame className="h-3 w-3 text-red-500" />}
                      </div>
                      {item.customizations && item.customizations.quantity > 1 && (
                        <div className="text-xs text-amber-700">Cantidad: {item.customizations.quantity}</div>
                      )}
                    </div>
                    <span className="font-medium text-orange-600">${item.price}</span>
                  </div>
                ))}
                {cart.length > 3 && (
                  <div className="text-center text-sm text-amber-700">
                    +{cart.length - 3} artículos más
                  </div>
                )}
                <div className="border-t border-amber-200 pt-3 flex justify-between font-medium text-amber-900">
                  <span>Total:</span>
                  <span className="text-orange-600">${calculateTotal()}</span>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Acciones */}
        <div className="space-y-3">
          <Button 
            onClick={onViewMenu} 
            className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700 text-white shadow-md"
            size="lg"
          >
            <Plus className="h-4 w-4 mr-2" />
            Agregar Productos
          </Button>

          {cart.length > 0 && (
            <>
              <Button 
                variant="outline" 
                onClick={onViewCart}
                className="w-full border-amber-300 text-amber-700 hover:bg-amber-100"
                size="lg"
              >
                <ShoppingCart className="h-4 w-4 mr-2" />
                Ver Consumo Completo
              </Button>
              
              <Button 
                variant="outline" 
                className="w-full border-orange-300 text-orange-700 hover:bg-orange-100"
                size="lg"
              >
                <Receipt className="h-4 w-4 mr-2" />
                Cerrar Mesa
              </Button>
            </>
          )}
        </div>

        {/* Info del puesto */}
        <Card className="bg-gradient-to-r from-orange-100 to-red-100 border-orange-300">
          <CardContent className="p-4">
            <div className="text-center">
              <div className="flex items-center justify-center gap-2 text-orange-900 font-medium">
                <Flame className="h-4 w-4" />
                <span>Barbacoa recién hecha</span>
              </div>
              <div className="text-xs text-orange-800 mt-1">
                ¡Servimos hasta agotar existencias del día!
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Columna lateral - Historial de Pedidos */}
      <div className="lg:col-span-1">
        <Card className="border-blue-200 bg-blue-50">
          <CardHeader>
            <CardTitle className="flex items-center justify-between text-blue-900">
              <div className="flex items-center gap-2">
                <Clock className="h-4 w-4" />
                Historial de Pedidos — Mesa {table.number}
              </div>
              <div className="flex gap-2">
                {/* Botón Cerrar cuenta */}
                {hasItemsForBilling && (
                  <Button
                    size="sm"
                    onClick={() => setShowCerrarCuentaModal(true)}
                    className="bg-orange-600 hover:bg-orange-700 text-white"
                    title="Cerrar cuenta"
                  >
                    <Calculator className="h-3 w-3 mr-1" />
                    Cerrar cuenta
                  </Button>
                )}
                
                {/* Botón Enviar Alerta */}
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setShowAlertModal(true)}
                  className="border-orange-300 text-orange-700 hover:bg-orange-100"
                  title="Enviar alerta a cocina"
                >
                  <AlertTriangle className="h-3 w-3" />
                </Button>

              </div>
            </CardTitle>
            <div className="flex gap-2 mt-3">
              <Dialog open={showClearDialog} onOpenChange={setShowClearDialog}>
                <DialogTrigger asChild>
                  <Button
                    variant="outline"
                    size="sm"
                    className="border-blue-300 text-blue-700 hover:bg-blue-100"
                  >
                    <Trash2 className="h-3 w-3 mr-1" />
                    Limpiar historial
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Limpiar historial de mesa</DialogTitle>
                    <DialogDescription>
                      Confirma si deseas limpiar el historial de pedidos para esta mesa
                    </DialogDescription>
                  </DialogHeader>
                  <div className="space-y-4">
                    <p className="text-sm text-gray-700">
                      ¿Confirmas que deseas limpiar el historial de Pedidos para la Mesa {table.number}? 
                      Esto no eliminará registros del sistema, solo ocultará la lista en esta sesión.
                    </p>
                    <div className="flex gap-2 pt-4">
                      <Button
                        variant="outline"
                        onClick={() => setShowClearDialog(false)}
                        className="flex-1"
                      >
                        Cancelar
                      </Button>
                      <Button
                        onClick={handleClearHistory}
                        className="flex-1 bg-red-600 hover:bg-red-700 text-white"
                      >
                        Limpiar historial
                      </Button>
                    </div>
                  </div>
                </DialogContent>
              </Dialog>
            </div>
          </CardHeader>
          <CardContent className="space-y-3">
            {orderHistory.slice(0, 6).map((order, index) => (
              <div 
                key={order.id} 
                className={`p-3 bg-white rounded border border-blue-200 ${
                  order.status === 'Enviado al Cajero' && index === 0 ? 'animate-pulse border-blue-400 bg-blue-50' : ''
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-blue-900">{order.id}</span>
                  <Badge className={getOrderStatusColor(order.status)} size="sm">
                    {order.status === 'Enviado al Cajero' && <Send className="h-3 w-3 mr-1" />}
                    {order.status}
                  </Badge>
                </div>
                <div className="text-xs text-blue-700 mb-1">
                  {order.items.join(', ')}
                </div>
                <div className="flex items-center gap-1 text-xs text-blue-600">
                  <Clock className="h-3 w-3" />
                  <span>{order.time}</span>
                </div>
              </div>
            ))}
            
            {orderHistory.length === 0 && (
              <div className="text-center py-6 text-blue-600">
                <ChefHat className="h-8 w-8 mx-auto mb-2 opacity-50" />
                <p className="text-sm">No hay pedidos recientes para esta mesa.</p>
                {showRestoreDemo && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={handleRestoreDemo}
                    className="mt-3 border-blue-300 text-blue-700 hover:bg-blue-100"
                  >
                    Restaurar demo
                  </Button>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Modales */}
      <AlertToKitchenModal
        isOpen={showAlertModal}
        onClose={() => setShowAlertModal(false)}
        orderId={orderHistory.length > 0 ? orderHistory[0].id : undefined}
        tableNumber={table.number}
        waiterName={user?.name || 'Mesero'}
      />



      <CerrarCuentaModal
        isOpen={showCerrarCuentaModal}
        onClose={() => setShowCerrarCuentaModal(false)}
        tableNumber={table.number}
        orderSummary={prepareOrderSummary()}
        waiterName={user?.name || 'Mesero'}
        onAccountSent={handleAccountSent}
      />
    </div>
  );
}