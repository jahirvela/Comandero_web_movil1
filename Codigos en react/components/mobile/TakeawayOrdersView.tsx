import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Separator } from '../ui/separator';
import { ArrowLeft, Clock, Phone, User, Package } from 'lucide-react';

// Datos de ejemplo de pedidos para llevar del mesero
const mockTakeawayOrders = [
  {
    id: 'ORD-003',
    customerName: 'Jahir',
    customerPhone: '55 1234 5678',
    items: [
      { name: 'Quesadilla de Barbacoa', quantity: 2, price: 80 },
      { name: 'Refresco', quantity: 2, price: 24 }
    ],
    total: 104,
    status: 'listo_para_recoger',
    pickupTime: 'Ahora',
    orderTime: new Date(Date.now() - 900000), // 15 min ago
    estimatedTime: '10-15 min'
  },
  {
    id: 'ORD-004',
    customerName: 'María',
    customerPhone: '55 9876 5432',
    items: [
      { name: 'Mix Barbacoa', quantity: 1, price: 95 },
      { name: 'Taco de Carnitas', quantity: 3, price: 66 }
    ],
    total: 161,
    status: 'en_preparacion',
    pickupTime: '14:30',
    orderTime: new Date(Date.now() - 1800000), // 30 min ago
    estimatedTime: '15-20 min'
  },
  {
    id: 'ORD-005',
    customerName: 'Carlos',
    customerPhone: null,
    items: [
      { name: 'Taco de Barbacoa', quantity: 4, price: 88 },
      { name: 'Agua de Horchata', quantity: 2, price: 36 }
    ],
    total: 124,
    status: 'entregado',
    pickupTime: '13:00',
    orderTime: new Date(Date.now() - 3600000), // 1 hour ago
    estimatedTime: '10-12 min'
  }
];

export function TakeawayOrdersView({ onBack }) {
  const [orders] = useState(mockTakeawayOrders);

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

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={onBack} className="text-amber-700 hover:bg-amber-100">
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h2 className="text-xl font-medium text-amber-900">Pedidos Para Llevar</h2>
          <p className="text-sm text-amber-700">
            {orders.length} {orders.length === 1 ? 'pedido' : 'pedidos'}
          </p>
        </div>
      </div>

      {orders.length === 0 ? (
        <Card className="border-amber-200">
          <CardContent className="p-8 text-center">
            <div className="text-amber-700">
              <Package className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No hay pedidos para llevar</p>
              <p className="text-sm">Los pedidos aparecerán aquí cuando los crees</p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {orders.map(order => (
            <Card key={order.id} className="border-amber-200">
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
                    <div key={index} className="flex justify-between text-sm text-amber-700 py-1">
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
                  <div>Tiempo estimado: {order.estimatedTime}</div>
                  {order.status === 'listo_para_recoger' && (
                    <div className="text-green-700 font-medium">
                      🎉 Pedido listo para recoger — {order.customerName}
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}