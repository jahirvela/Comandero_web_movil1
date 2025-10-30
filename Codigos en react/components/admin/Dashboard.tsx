import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { 
  TrendingUp, 
  Users, 
  DollarSign, 
  AlertCircle, 
  Clock,
  Receipt,
  Calculator,
  Package,
  FileDown,
  ExternalLink
} from 'lucide-react';
import { LogoC } from '../RoleSpecificIcons';

// Datos mock para el consumo del día
const mockDailyConsumption = {
  ventasLocal: 2150,
  ventasParaLlevar: 1100,
  ventasEfectivo: 3250,
  porCobrar: 373.05,
  totalNeto: 3623.05
};

const mockOrdersDetail = [
  {
    id: 'ORD-001',
    origen: 'Mesa 5',
    productos: ['3x Taco de Barbacoa', '1x Consomé Grande', '2x Agua de Horchata'],
    total: 157.50,
    metodoPago: 'Efectivo',
    estado: 'Cobrado',
    hora: '14:35'
  },
  {
    id: 'ORD-002',
    origen: 'Para llevar: Jahir',
    productos: ['2x Quesadilla de Barbacoa', '2x Refresco'],
    total: 104.00,
    metodoPago: 'Efectivo',
    estado: 'Pendiente',
    hora: '14:42'
  },
  {
    id: 'ORD-003',
    origen: 'Mesa 3',
    productos: ['1x Mix Barbacoa', '2x Taco de Carnitas'],
    total: 139.00,
    metodoPago: 'Efectivo',
    estado: 'Cobrado',
    hora: '13:28'
  },
  {
    id: 'ORD-004',
    origen: 'Para llevar: María',
    productos: ['4x Taco de Barbacoa', '1x Consomé Chico'],
    total: 112.50,
    metodoPago: 'Efectivo',
    estado: 'Cobrado',
    hora: '15:15'
  }
];

export function Dashboard() {
  const [selectedFilter, setSelectedFilter] = useState('todos');

  const handleExportCSV = () => {
    alert('Exportando datos del consumo del día en formato CSV...');
  };

  const handleGoToCashClose = () => {
    alert('Redirigiendo a Cierre de Caja...');
  };

  const filteredOrders = mockOrdersDetail.filter(order => {
    if (selectedFilter === 'todos') return true;
    if (selectedFilter === 'mesas') return !order.origen.includes('Para llevar');
    if (selectedFilter === 'para_llevar') return order.origen.includes('Para llevar');
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <LogoC size={48} />
        <div>
          <h1 className="text-3xl text-amber-900 mb-2">
            Panel de Control
          </h1>
          <p className="text-amber-700">Resumen general del puesto de barbacoa</p>
        </div>
      </div>

      {/* Estadísticas generales */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border-amber-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-amber-700">Ventas del Día</p>
                <p className="text-2xl font-medium text-green-600">$3,250</p>
                <p className="text-xs text-green-600">+12.5% vs ayer</p>
              </div>
              <TrendingUp className="h-8 w-8 text-amber-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-amber-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-amber-700">Órdenes Activas</p>
                <p className="text-2xl font-medium text-blue-600">8</p>
                <p className="text-xs text-blue-600">3 en cocina</p>
              </div>
              <Receipt className="h-8 w-8 text-amber-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-amber-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-amber-700">Mesas Ocupadas</p>
                <p className="text-2xl font-medium text-orange-600">5/8</p>
                <p className="text-xs text-orange-600">62.5% ocupación</p>
              </div>
              <Users className="h-8 w-8 text-amber-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-amber-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-amber-700">Stock Crítico</p>
                <p className="text-2xl font-medium text-red-600">2</p>
                <p className="text-xs text-red-600">Carnitas, Tortillas</p>
              </div>
              <AlertCircle className="h-8 w-8 text-amber-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Módulo Consumo del Día */}
      <Card className="border-amber-200">
        <CardHeader>
          <CardTitle className="flex items-center justify-between text-amber-900">
            <span>Consumo del Día</span>
            <div className="flex gap-2">
              <Button 
                variant="outline" 
                size="sm" 
                onClick={handleExportCSV}
                className="border-amber-300 text-amber-700"
              >
                <FileDown className="h-4 w-4 mr-1" />
                Exportar CSV
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                onClick={handleGoToCashClose}
                className="border-amber-300 text-amber-700"
              >
                <ExternalLink className="h-4 w-4 mr-1" />
                Ver en Cierre de Caja
              </Button>
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Cards de resumen */}
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
            <Card className="border-green-200 bg-green-50">
              <CardContent className="p-4">
                <div className="text-center">
                  <p className="text-sm text-green-700">Ventas en Local</p>
                  <p className="text-xl font-medium text-green-800">${mockDailyConsumption.ventasLocal}</p>
                </div>
              </CardContent>
            </Card>

            <Card className="border-blue-200 bg-blue-50">
              <CardContent className="p-4">
                <div className="text-center">
                  <p className="text-sm text-blue-700">Ventas Para llevar</p>
                  <p className="text-xl font-medium text-blue-800">${mockDailyConsumption.ventasParaLlevar}</p>
                </div>
              </CardContent>
            </Card>

            <Card className="border-amber-200 bg-amber-50">
              <CardContent className="p-4">
                <div className="text-center">
                  <p className="text-sm text-amber-700">Ventas Efectivo</p>
                  <p className="text-xl font-medium text-amber-800">${mockDailyConsumption.ventasEfectivo}</p>
                </div>
              </CardContent>
            </Card>

            <Card className="border-red-200 bg-red-50">
              <CardContent className="p-4">
                <div className="text-center">
                  <p className="text-sm text-red-700">Por cobrar</p>
                  <p className="text-xl font-medium text-red-800">${mockDailyConsumption.porCobrar}</p>
                </div>
              </CardContent>
            </Card>

            <Card className="border-purple-200 bg-purple-50">
              <CardContent className="p-4">
                <div className="text-center">
                  <p className="text-sm text-purple-700">Total Neto</p>
                  <p className="text-xl font-medium text-purple-800">${mockDailyConsumption.totalNeto}</p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Filtros */}
          <div className="flex items-center gap-2">
            <span className="text-sm text-amber-700">Mostrar:</span>
            <div className="flex gap-1">
              <Button
                variant={selectedFilter === 'todos' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setSelectedFilter('todos')}
                className={selectedFilter === 'todos' ? 'bg-amber-600 hover:bg-amber-700' : 'border-amber-300 text-amber-700'}
              >
                Todos
              </Button>
              <Button
                variant={selectedFilter === 'para_llevar' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setSelectedFilter('para_llevar')}
                className={selectedFilter === 'para_llevar' ? 'bg-amber-600 hover:bg-amber-700' : 'border-amber-300 text-amber-700'}
              >
                Solo para llevar
              </Button>
              <Button
                variant={selectedFilter === 'mesas' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setSelectedFilter('mesas')}
                className={selectedFilter === 'mesas' ? 'bg-amber-600 hover:bg-amber-700' : 'border-amber-300 text-amber-700'}
              >
                Mesas
              </Button>
            </div>
          </div>

          {/* Tabla de detalles */}
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead>
                <tr className="border-b border-amber-200">
                  <th className="text-left p-3 text-amber-900">ID</th>
                  <th className="text-left p-3 text-amber-900">Origen</th>
                  <th className="text-left p-3 text-amber-900">Productos</th>
                  <th className="text-left p-3 text-amber-900">Total</th>
                  <th className="text-left p-3 text-amber-900">Método de pago</th>
                  <th className="text-left p-3 text-amber-900">Estado</th>
                  <th className="text-left p-3 text-amber-900">Hora</th>
                </tr>
              </thead>
              <tbody>
                {filteredOrders.map((order, index) => (
                  <tr key={order.id} className={`border-b border-amber-100 ${index % 2 === 0 ? 'bg-amber-25' : ''}`}>
                    <td className="p-3 text-amber-800">{order.id}</td>
                    <td className="p-3">
                      {order.origen.includes('Para llevar') ? (
                        <Badge className="bg-blue-100 text-blue-800 border-blue-300">
                          {order.origen}
                        </Badge>
                      ) : (
                        <Badge className="bg-green-100 text-green-800 border-green-300">
                          {order.origen}
                        </Badge>
                      )}
                    </td>
                    <td className="p-3 text-amber-700">
                      <div className="text-sm">
                        {order.productos.join(', ')}
                      </div>
                    </td>
                    <td className="p-3 text-amber-800 font-medium">${order.total}</td>
                    <td className="p-3 text-amber-700">{order.metodoPago}</td>
                    <td className="p-3">
                      <Badge className={
                        order.estado === 'Cobrado' 
                          ? 'bg-green-100 text-green-800 border-green-300'
                          : 'bg-orange-100 text-orange-800 border-orange-300'
                      }>
                        {order.estado}
                      </Badge>
                    </td>
                    <td className="p-3 text-amber-700">{order.hora}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Resumen de estado actual */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="border-amber-200">
          <CardHeader>
            <CardTitle className="text-amber-900">Estado de Mesas</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-4 gap-2">
              {[1, 2, 3, 4, 5, 6, 7, 8].map(num => (
                <div key={num} className="p-3 border border-amber-200 rounded text-center">
                  <div className="font-medium text-amber-900">Mesa {num}</div>
                  <Badge className={
                    [1, 4, 7, 8].includes(num) 
                      ? 'bg-green-100 text-green-800 border-green-300'
                      : [2, 3, 5].includes(num)
                      ? 'bg-red-100 text-red-800 border-red-300'
                      : 'bg-blue-100 text-blue-800 border-blue-300'
                  }>
                    {[1, 4, 7, 8].includes(num) ? 'Libre' : [2, 3, 5].includes(num) ? 'Ocupada' : 'Reservada'}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="border-amber-200">
          <CardHeader>
            <CardTitle className="text-amber-900">Alertas de Inventario</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="p-3 bg-red-50 border border-red-200 rounded">
              <div className="flex items-center justify-between">
                <span className="text-red-900">Carnitas</span>
                <Badge className="bg-red-100 text-red-800 border-red-300">5 kg</Badge>
              </div>
              <p className="text-xs text-red-700 mt-1">Stock crítico</p>
            </div>
            
            <div className="p-3 bg-orange-50 border border-orange-200 rounded">
              <div className="flex items-center justify-between">
                <span className="text-orange-900">Tortillas</span>
                <Badge className="bg-orange-100 text-orange-800 border-orange-300">2 paquetes</Badge>
              </div>
              <p className="text-xs text-orange-700 mt-1">Stock bajo</p>
            </div>

            <div className="p-3 bg-orange-50 border border-orange-200 rounded">
              <div className="flex items-center justify-between">
                <span className="text-orange-900">Barbacoa de Res</span>
                <Badge className="bg-orange-100 text-orange-800 border-orange-300">15 kg</Badge>
              </div>
              <p className="text-xs text-orange-700 mt-1">Stock bajo</p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}