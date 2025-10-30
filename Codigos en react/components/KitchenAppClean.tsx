import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Separator } from './ui/separator';
import { NotificationPanel } from './NotificationPanel';
import { 
  Clock, 
  ChefHat, 
  CheckCircle, 
  Timer, 
  Flame, 
  Users,
  Filter,
  LogOut,
  Utensils,
  Coffee,
  Soup,
  Bell
} from 'lucide-react';
import { useNotifications } from './NotificationContext';

// Datos de ejemplo de pedidos en cocina
const mockOrders = [
  {
    id: 'ORD-001',
    tableNumber: 5,
    items: [
      { id: 1, name: 'Taco de Barbacoa', quantity: 3, station: 'tacos', notes: 'Sin cebolla' },
      { id: 2, name: 'Consomé Grande', quantity: 1, station: 'consomes', notes: '' },
      { id: 3, name: 'Agua de Horchata', quantity: 2, station: 'bebidas', notes: '' }
    ],
    status: 'pendiente',
    orderTime: new Date(Date.now() - 300000), // 5 min ago
    estimatedTime: 15,
    waiter: 'Juan Martínez',
    priority: 'normal',
    isTakeaway: false
  },
  {
    id: 'ORD-002',
    tableNumber: 3,
    items: [
      { id: 4, name: 'Mix Barbacoa', quantity: 1, station: 'consomes', notes: 'Bien dorado' },
      { id: 5, name: 'Taco de Carnitas', quantity: 2, station: 'tacos', notes: '' }
    ],
    status: 'en_preparacion',
    orderTime: new Date(Date.now() - 600000), // 10 min ago
    estimatedTime: 20,
    waiter: 'Juan Martínez',
    priority: 'alta',
    isTakeaway: false
  },
  {
    id: 'ORD-003',
    tableNumber: null,
    items: [
      { id: 6, name: 'Quesadilla de Barbacoa', quantity: 2, station: 'tacos', notes: 'Extra queso' },
      { id: 7, name: 'Refresco', quantity: 3, station: 'bebidas', notes: 'Con hielo' }
    ],
    status: 'listo_para_recoger',
    orderTime: new Date(Date.now() - 1200000), // 20 min ago
    estimatedTime: 10,
    waiter: 'Juan Martínez',
    priority: 'normal',
    isTakeaway: true,
    customerName: 'Jahir',
    customerPhone: '55 1234 5678',
    pickupTime: 'Ahora'
  }
];

export function KitchenApp({ user, onLogout }) {
  const [orders, setOrders] = useState(mockOrders);
  const [selectedStation, setSelectedStation] = useState('todas');
  const [selectedStatus, setSelectedStatus] = useState('todas');
  const [showNotifications, setShowNotifications] = useState(false);
  const [showTakeawayOnly, setShowTakeawayOnly] = useState(false);
  
  const { addNotification, getUnreadCount } = useNotifications();

  const stations = [
    { id: 'todas', name: 'Todas las Estaciones', icon: ChefHat },
    { id: 'tacos', name: 'Tacos', icon: Utensils },
    { id: 'consomes', name: 'Consomes', icon: Soup },
    { id: 'bebidas', name: 'Bebidas', icon: Coffee }
  ];

  const statusOptions = [
    { id: 'todas', name: 'Todos los Estados', color: 'default' },
    { id: 'pendiente', name: 'Pendientes', color: 'destructive' },
    { id: 'en_preparacion', name: 'En Preparación', color: 'secondary' },
    { id: 'listo', name: 'Listos', color: 'default' },
    { id: 'listo_para_recoger', name: 'Listos para Recoger', color: 'default' }
  ];

  const filteredOrders = orders.filter(order => {
    const stationMatch = selectedStation === 'todas' || 
      order.items.some(item => item.station === selectedStation);
    const statusMatch = selectedStatus === 'todas' || order.status === selectedStatus;
    const takeawayMatch = !showTakeawayOnly || order.isTakeaway;
    return stationMatch && statusMatch && takeawayMatch;
  });

  const getStatusColor = (status) => {
    switch (status) {
      case 'pendiente': return 'bg-red-100 text-red-800 border-red-300';
      case 'en_preparacion': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'listo': return 'bg-green-100 text-green-800 border-green-300';
      case 'listo_para_recoger': return 'bg-green-100 text-green-800 border-green-300';
      default: return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 'alta': return 'bg-red-100 text-red-800 border-red-300';
      case 'normal': return 'bg-blue-100 text-blue-800 border-blue-300';
      default: return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const formatElapsedTime = (orderTime) => {
    const elapsed = Math.floor((Date.now() - orderTime.getTime()) / 60000);
    return `${elapsed} min`;
  };

  const updateOrderStatus = (orderId, newStatus) => {
    const order = orders.find(o => o.id === orderId);
    
    setOrders(prev => prev.map(order => 
      order.id === orderId ? { ...order, status: newStatus } : order
    ));

    // Enviar notificación al mesero cuando el pedido esté listo
    if ((newStatus === 'listo' || newStatus === 'listo_para_recoger') && order) {
      const message = order.isTakeaway 
        ? `Pedido listo para recoger — ${order.customerName}`
        : `Mesa ${order.tableNumber} - Pedido completado y listo para servir`;
      
      addNotification({
        type: 'order_ready',
        title: order.isTakeaway ? 'Pedido Para Llevar Listo' : 'Pedido Listo',
        message: message,
        targetRole: 'mesero',
        targetUser: order.waiter,
        fromUser: user.name,
        fromRole: user.type,
        tableNumber: order.tableNumber,
        orderId: order.id,
        priority: 'high',
        isTakeaway: order.isTakeaway,
        customerName: order.customerName
      });
      
      if (order.isTakeaway && newStatus === 'listo_para_recoger') {
        alert(`Pedido listo para recoger — ${order.customerName}`);
      }
    }
  };

  const updateEstimatedTime = (orderId, newTime) => {
    setOrders(prev => prev.map(order => 
      order.id === orderId ? { ...order, estimatedTime: parseInt(newTime) } : order
    ));
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-red-50">
      {/* Header */}
      <header className="bg-white border-b border-orange-200 shadow-sm">
        <div className="px-3 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 sm:w-10 sm:h-10 bg-gradient-to-br from-orange-600 to-red-600 rounded-lg flex items-center justify-center">
                <ChefHat className="h-4 w-4 sm:h-5 sm:w-5 text-white" />
              </div>
              <div>
                <h1 className="text-sm sm:text-base font-medium text-orange-900">Filtros de Cocina - Comandix</h1>
                <p className="text-xs sm:text-sm text-orange-700">{user.name} • {user.role}</p>
              </div>
            </div>
            
            <div className="flex items-center gap-2 sm:gap-3">
              <Badge className="bg-orange-100 text-orange-800 border-orange-300 text-xs">
                {filteredOrders.length} pedidos
              </Badge>
              <Button variant="outline" size="sm" onClick={onLogout} className="border-orange-300">
                <LogOut className="h-3 w-3 sm:h-4 sm:w-4" />
              </Button>
            </div>
          </div>
        </div>
      </header>

      <div className="p-3 sm:p-4">
        {/* Filtros */}
        <Card className="mb-4 sm:mb-6 border-orange-200">
          <CardHeader className="pb-3">
            <CardTitle className="flex items-center gap-2 text-orange-900 text-base">
              <Filter className="h-4 w-4" />
              Filtros de Cocina
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col sm:flex-row gap-3 sm:gap-4">
              <div className="flex-1 min-w-0">
                <label className="text-sm font-medium text-orange-900 mb-2 block">Estación</label>
                <Select value={selectedStation} onValueChange={setSelectedStation}>
                  <SelectTrigger className="border-orange-200 w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {stations.map(station => (
                      <SelectItem key={station.id} value={station.id}>
                        <div className="flex items-center gap-2">
                          <station.icon className="h-4 w-4" />
                          {station.name}
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="flex-1 min-w-0">
                <label className="text-sm font-medium text-orange-900 mb-2 block">Estado</label>
                <Select value={selectedStatus} onValueChange={setSelectedStatus}>
                  <SelectTrigger className="border-orange-200 w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {statusOptions.map(status => (
                      <SelectItem key={status.id} value={status.id}>
                        <span className="truncate">{status.name}</span>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="flex-1 min-w-0">
                <label className="text-sm font-medium text-orange-900 mb-2 block">Para Llevar</label>
                <Select value={showTakeawayOnly.toString()} onValueChange={(value) => setShowTakeawayOnly(value === 'true')}>
                  <SelectTrigger className="border-orange-200 w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="false">Todos los pedidos</SelectItem>
                    <SelectItem value="true">Solo para llevar</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Lista de Pedidos */}
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-3 sm:gap-4">
          {filteredOrders.map(order => (
            <Card key={order.id} className={`border-2 ${
              order.priority === 'alta' ? 'border-red-300 bg-red-50' : 'border-orange-200'
            }`}>
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2 flex-wrap">
                    <Badge className={getPriorityColor(order.priority)}>
                      {order.priority === 'alta' ? '🔥 URGENTE' : 'Normal'}
                    </Badge>
                    <Badge className={getStatusColor(order.status)}>
                      {order.status.replace('_', ' ').toUpperCase()}
                    </Badge>
                    {order.isTakeaway && (
                      <Badge className="bg-blue-100 text-blue-800 border-blue-300">
                        📦 Para llevar — {order.customerName}
                      </Badge>
                    )}
                  </div>
                  <div className="text-right">
                    <div className="font-medium text-orange-900">
                      {order.isTakeaway ? `Para llevar` : `Mesa ${order.tableNumber}`}
                    </div>
                    <div className="text-xs text-orange-700">{order.id}</div>
                  </div>
                </div>
                
                {order.isTakeaway && order.customerPhone && (
                  <div className="text-sm text-orange-700 mt-2">
                    📞 {order.customerPhone}
                  </div>
                )}
                
                <div className="flex items-center justify-between text-sm text-orange-700">
                  <div className="flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    Hace {formatElapsedTime(order.orderTime)}
                  </div>
                  <div className="flex items-center gap-1">
                    <Users className="h-3 w-3" />
                    {order.waiter}
                  </div>
                </div>
              </CardHeader>
              
              <CardContent className="space-y-4">
                {/* Items del pedido */}
                <div className="space-y-2">
                  {order.items.map(item => (
                    <div key={item.id} className="p-2 bg-white rounded border border-orange-100">
                      <div className="flex items-center justify-between">
                        <div className="flex-1">
                          <div className="font-medium text-orange-900">{item.name}</div>
                          {item.notes && (
                            <div className="text-xs text-orange-600 italic">📝 {item.notes}</div>
                          )}
                        </div>
                        <div className="flex items-center gap-2">
                          <Badge variant="outline" className="border-orange-300 text-orange-700">
                            x{item.quantity}
                          </Badge>
                          <Badge variant="outline" className="border-blue-300 text-blue-700 text-xs">
                            {item.station}
                          </Badge>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>

                <Separator className="border-orange-200" />

                {/* Tiempo estimado */}
                <div className="flex items-center justify-between">
                  <label className="text-sm font-medium text-orange-900">Tiempo estimado:</label>
                  <Select 
                    value={order.estimatedTime.toString()} 
                    onValueChange={(value) => updateEstimatedTime(order.id, value)}
                  >
                    <SelectTrigger className="w-24 border-orange-200">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="5">5 min</SelectItem>
                      <SelectItem value="10">10 min</SelectItem>
                      <SelectItem value="15">15 min</SelectItem>
                      <SelectItem value="20">20 min</SelectItem>
                      <SelectItem value="30">30 min</SelectItem>
                      <SelectItem value="45">45 min</SelectItem>
                      <SelectItem value="60">1 hora</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Acciones */}
                <div className="flex gap-2">
                  {order.status === 'pendiente' && (
                    <Button 
                      onClick={() => updateOrderStatus(order.id, 'en_preparacion')}
                      className="flex-1 bg-yellow-600 hover:bg-yellow-700"
                      size="sm"
                    >
                      <Timer className="h-3 w-3 mr-1" />
                      Iniciar
                    </Button>
                  )}
                  
                  {order.status === 'en_preparacion' && (
                    <Button 
                      onClick={() => updateOrderStatus(order.id, order.isTakeaway ? 'listo_para_recoger' : 'listo')}
                      className="flex-1 bg-green-600 hover:bg-green-700"
                      size="sm"
                    >
                      <CheckCircle className="h-3 w-3 mr-1" />
                      {order.isTakeaway ? 'Listo para Recoger' : 'Listo'}
                    </Button>
                  )}
                  
                  {(order.status === 'listo' || order.status === 'listo_para_recoger') && (
                    <div className="flex-1 p-2 text-center text-sm text-green-700 bg-green-100 rounded border border-green-300">
                      ✅ {order.isTakeaway ? 'Listo para recoger' : 'Pedido completado'}
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {filteredOrders.length === 0 && (
          <Card className="border-orange-200">
            <CardContent className="p-8 text-center">
              <ChefHat className="h-12 w-12 mx-auto mb-4 text-orange-400" />
              <p className="text-orange-700">No hay pedidos que coincidan con los filtros actuales</p>
              <p className="text-sm text-orange-600">Ajusta los filtros para ver otros pedidos</p>
            </CardContent>
          </Card>
        )}

        {/* Panel de Notificaciones */}
        <NotificationPanel
          userRole={user.type}
          userName={user.name}
          isOpen={showNotifications}
          onClose={() => setShowNotifications(false)}
        />
      </div>
    </div>
  );
}