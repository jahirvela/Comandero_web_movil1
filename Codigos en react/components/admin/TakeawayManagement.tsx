import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Separator } from '../ui/separator';
import { 
  Package, 
  Search, 
  Filter,
  Eye,
  Printer,
  Trash2,
  Clock,
  Phone,
  User,
  DollarSign
} from 'lucide-react';

// Datos de ejemplo de pedidos para llevar
const mockTakeawayOrders = [
  {
    id: 'ORD-001',
    customerName: 'Jahir',
    customerPhone: '55 1234 5678',
    items: [
      { name: 'Taco de Barbacoa', quantity: 3, price: 66 },
      { name: 'Consomé Grande', quantity: 1, price: 35 },
      { name: 'Agua de Horchata', quantity: 2, price: 36 }
    ],
    total: 137,
    status: 'listo_para_recoger',
    pickupTime: '14:30',
    createdBy: 'Juan Martínez',
    orderTime: new Date(Date.now() - 1800000), // 30 min ago
    estimatedTime: '15-20 min'
  },
  {
    id: 'ORD-002',
    customerName: 'María',
    customerPhone: '55 9876 5432',
    items: [
      { name: 'Mix Barbacoa', quantity: 1, price: 95 },
      { name: 'Quesadilla de Barbacoa', quantity: 2, price: 80 }
    ],
    total: 175,
    status: 'en_preparacion',
    pickupTime: 'Ahora',
    createdBy: 'Ana García',
    orderTime: new Date(Date.now() - 900000), // 15 min ago
    estimatedTime: '10-15 min'
  },
  {
    id: 'ORD-003',
    customerName: 'Carlos',
    customerPhone: null,
    items: [
      { name: 'Taco de Carnitas', quantity: 4, price: 88 },
      { name: 'Refresco', quantity: 2, price: 24 }
    ],
    total: 112,
    status: 'entregado',
    pickupTime: '13:00',
    createdBy: 'Luis Rodríguez',
    orderTime: new Date(Date.now() - 3600000), // 1 hour ago
    estimatedTime: '10-12 min'
  }
];

export function TakeawayManagement() {
  const [orders, setOrders] = useState(mockTakeawayOrders);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('todos');

  const getStatusColor = (status) => {
    switch (status) {
      case 'pendiente': return 'bg-red-100 text-red-800 border-red-300';
      case 'en_preparacion': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'listo_para_recoger': return 'bg-green-100 text-green-800 border-green-300';
      case 'entregado': return 'bg-blue-100 text-blue-800 border-blue-300';
      default: return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const formatElapsedTime = (orderTime) => {
    const elapsed = Math.floor((Date.now() - orderTime.getTime()) / 60000);
    return `${elapsed} min`;
  };

  const filteredOrders = orders.filter(order => {
    const matchesSearch = order.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         order.id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'todos' || order.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const handleViewOrder = (orderId) => {
    alert(`Ver detalles del pedido ${orderId}`);
  };

  const handleReprintOrder = (orderId) => {
    alert(`Reimprimiendo ticket del pedido ${orderId}`);
  };

  const handleDeleteOrder = (orderId) => {
    if (confirm('¿Estás seguro de que deseas eliminar este pedido?')) {
      setOrders(prev => prev.filter(order => order.id !== orderId));
      alert('Pedido eliminado correctamente');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-medium text-amber-900 flex items-center gap-3">
            📦 Pedidos Para Llevar
          </h1>
          <p className="text-amber-700 mt-1">Gestión completa de pedidos takeaway</p>
        </div>
        
        <Badge className="bg-blue-100 text-blue-800 border-blue-300 px-4 py-2">
          {filteredOrders.length} pedidos
        </Badge>
      </div>

      {/* Filtros */}
      <Card className="border-amber-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-amber-900">
            <Filter className="h-4 w-4" />
            Filtros de Búsqueda
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1">
              <Label htmlFor="search" className="text-amber-900">Buscar por cliente o ID</Label>
              <div className="relative mt-2">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-amber-500 h-4 w-4" />
                <Input
                  id="search"
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Nombre del cliente o ID del pedido..."
                  className="pl-10 border-amber-200 focus:border-amber-500"
                />
              </div>
            </div>
            
            <div className="flex-1">
              <Label htmlFor="status" className="text-amber-900">Estado</Label>
              <select
                id="status"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="mt-2 w-full p-2 border border-amber-200 rounded-md focus:border-amber-500 focus:outline-none"
              >
                <option value="todos">Todos los estados</option>
                <option value="pendiente">Pendiente</option>
                <option value="en_preparacion">En Preparación</option>
                <option value="listo_para_recoger">Listo para Recoger</option>
                <option value="entregado">Entregado</option>
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Lista de pedidos */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {filteredOrders.map(order => (
          <Card key={order.id} className="border-amber-200 shadow-sm">
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Badge className="bg-blue-100 text-blue-800 border-blue-300">
                    📦 Para llevar
                  </Badge>
                  <Badge className={getStatusColor(order.status)}>
                    {order.status.replace('_', ' ').toUpperCase()}
                  </Badge>
                </div>
                <div className="text-right">
                  <div className="font-medium text-amber-900">{order.id}</div>
                  <div className="text-xs text-amber-700">
                    Hace {formatElapsedTime(order.orderTime)}
                  </div>
                </div>
              </div>
            </CardHeader>
            
            <CardContent className="space-y-4">
              {/* Información del cliente */}
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4 text-amber-600" />
                  <span className="font-medium text-amber-900">{order.customerName}</span>
                </div>
                {order.customerPhone && (
                  <div className="flex items-center gap-2">
                    <Phone className="h-4 w-4 text-amber-600" />
                    <span className="text-amber-700">{order.customerPhone}</span>
                  </div>
                )}
                <div className="flex items-center gap-2">
                  <Clock className="h-4 w-4 text-amber-600" />
                  <span className="text-amber-700">
                    Recogida: {order.pickupTime}
                  </span>
                </div>
              </div>

              <Separator className="border-amber-200" />

              {/* Items del pedido */}
              <div className="space-y-2">
                <div className="font-medium text-amber-900">Productos:</div>
                {order.items.map((item, index) => (
                  <div key={index} className="flex justify-between text-sm text-amber-700">
                    <span>{item.quantity}x {item.name}</span>
                    <span>${item.price}</span>
                  </div>
                ))}
                
                <Separator className="border-amber-200" />
                
                <div className="flex justify-between font-medium text-amber-900">
                  <span>Total:</span>
                  <span className="text-orange-600">${order.total}</span>
                </div>
              </div>

              <Separator className="border-amber-200" />

              {/* Información adicional */}
              <div className="text-sm text-amber-700 space-y-1">
                <div>Creado por: {order.createdBy}</div>
                <div>Tiempo estimado: {order.estimatedTime}</div>
              </div>

              {/* Acciones */}
              <div className="flex gap-2">
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={() => handleViewOrder(order.id)}
                  className="flex-1 border-amber-300 text-amber-700 hover:bg-amber-50"
                >
                  <Eye className="h-3 w-3 mr-1" />
                  Ver
                </Button>
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={() => handleReprintOrder(order.id)}
                  className="flex-1 border-blue-300 text-blue-700 hover:bg-blue-50"
                >
                  <Printer className="h-3 w-3 mr-1" />
                  Reimprimir
                </Button>
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={() => handleDeleteOrder(order.id)}
                  className="border-red-300 text-red-700 hover:bg-red-50"
                >
                  <Trash2 className="h-3 w-3" />
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredOrders.length === 0 && (
        <Card className="border-amber-200">
          <CardContent className="p-8 text-center">
            <Package className="h-12 w-12 mx-auto mb-4 text-amber-400" />
            <p className="text-amber-700">No hay pedidos para llevar que coincidan con los filtros</p>
            <p className="text-sm text-amber-600">Ajusta los filtros para ver otros pedidos</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}