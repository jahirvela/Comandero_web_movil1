import React from 'react';
import { Card, CardContent } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Users, RotateCcw } from 'lucide-react';
import { toast } from 'sonner';

const tables = [
  { id: 1, number: 1, status: 'libre', seats: 4, position: { x: 1, y: 1 } },
  { id: 2, number: 2, status: 'ocupada', seats: 2, position: { x: 2, y: 1 }, customers: 2 },
  { id: 3, number: 3, status: 'reservada', seats: 6, position: { x: 3, y: 1 }, reservation: 'Familia López - 14:30' },
  { id: 4, number: 4, status: 'en-limpieza', seats: 4, position: { x: 1, y: 2 } },
  { id: 5, number: 5, status: 'libre', seats: 2, position: { x: 2, y: 2 } },
  { id: 6, number: 6, status: 'ocupada', seats: 8, position: { x: 3, y: 2 }, customers: 6 },
  { id: 7, number: 7, status: 'libre', seats: 4, position: { x: 1, y: 3 } },
  { id: 8, number: 8, status: 'ocupada', seats: 4, position: { x: 2, y: 3 }, customers: 4, orderValue: 180 },
  { id: 9, number: 9, status: 'libre', seats: 2, position: { x: 3, y: 3 } },
];

const getStatusColor = (status) => {
  switch (status) {
    case 'libre': return 'bg-green-100 border-green-300 hover:bg-green-200 text-green-800';
    case 'ocupada': return 'bg-red-100 border-red-300 hover:bg-red-200 text-red-800';
    case 'en-limpieza': return 'bg-gray-100 border-gray-300 hover:bg-gray-200 text-gray-800';
    case 'reservada': return 'bg-yellow-100 border-yellow-300 hover:bg-yellow-200 text-yellow-800';
    default: return 'bg-gray-100 border-gray-300';
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

const getStatusIcon = (status) => {
  switch (status) {
    case 'libre': return '🟢';
    case 'ocupada': return '🔴';
    case 'en-limpieza': return '⚪';
    case 'reservada': return '🟡';
    default: return '⚪';
  }
};

export function FloorView({ onTableSelect }) {
  const [tablesState, setTablesState] = React.useState(tables);

  const occupiedTables = tablesState.filter(t => t.status !== 'libre').length;
  const occupancyRate = (occupiedTables / tablesState.length * 100).toFixed(0);

  const changeTableStatus = (tableId, newStatus, e) => {
    e.stopPropagation();
    
    setTablesState(prev => prev.map(table => {
      if (table.id === tableId) {
        const updatedTable = { ...table, status: newStatus };
        
        // Limpiar datos específicos según el estado
        if (newStatus === 'libre' || newStatus === 'en-limpieza') {
          delete updatedTable.customers;
          delete updatedTable.orderValue;
        }
        
        return updatedTable;
      }
      return table;
    }));

    // Mostrar toast de confirmación
    toast(`Mesa ${tablesState.find(t => t.id === tableId)?.number} marcada como ${getStatusText(newStatus)}`);
  };

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg sm:text-xl font-medium text-amber-900">Plano de Mesas</h2>
          <p className="text-xs sm:text-sm text-amber-700">
            {new Date().toLocaleDateString('es-MX', { 
              weekday: 'long', 
              day: 'numeric',
              month: 'long'
            })}
          </p>
        </div>
        <div className="text-right">
          <div className="text-lg font-medium text-amber-900">{occupancyRate}%</div>
          <div className="text-xs text-amber-700">Ocupación</div>
        </div>
      </div>

      {/* Leyenda de estados */}
      <div className="flex flex-wrap gap-2 p-3 bg-amber-50 rounded-lg border border-amber-200">
        <Badge className="bg-green-100 text-green-800 border-green-300 text-xs">🟢 Libre</Badge>
        <Badge className="bg-red-100 text-red-800 border-red-300 text-xs">🔴 Ocupada</Badge>
        <Badge className="bg-gray-100 text-gray-800 border-gray-300 text-xs">⚪ En Limpieza</Badge>
        <Badge className="bg-yellow-100 text-yellow-800 border-yellow-300 text-xs">🟡 Reservada</Badge>
      </div>

      {/* Grid de mesas - Mejorado para todas las pantallas */}
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3 sm:gap-4 lg:gap-5">
        {tablesState.map((table) => (
          <Card
            key={table.id}
            className={`cursor-pointer transition-all duration-200 ${getStatusColor(table.status)} border-2 shadow-sm hover:shadow-md relative`}
            onClick={() => onTableSelect(table)}
          >
            <CardContent className="p-3 sm:p-4 lg:p-5 text-center">
              <div className="space-y-2 lg:space-y-3">
                <div className="flex items-center justify-center gap-1 lg:gap-2">
                  <span className="text-base sm:text-lg lg:text-xl">{getStatusIcon(table.status)}</span>
                  <span className="text-sm sm:text-base lg:text-lg font-medium">Mesa {table.number}</span>
                </div>
                
                <Badge variant="outline" className="text-xs sm:text-sm lg:text-base">
                  {getStatusText(table.status)}
                </Badge>
                
                <div className="text-xs sm:text-sm lg:text-base text-muted-foreground space-y-1">
                  <div>{table.seats} lugares</div>
                  {table.customers && (
                    <div className="font-medium">{table.customers} comensales</div>
                  )}
                  {table.orderValue && (
                    <div className="text-xs sm:text-sm lg:text-base font-medium text-orange-700">${table.orderValue}</div>
                  )}
                  {table.reservation && (
                    <div className="text-xs sm:text-sm font-medium text-yellow-700">
                      <span className="hidden md:inline">Reserva: </span>
                      {table.reservation.split(' - ')[1]}
                    </div>
                  )}
                </div>

                {/* Selector de estado de mesa */}
                <div className="mt-2 lg:mt-3" onClick={(e) => e.stopPropagation()}>
                  <Select value={table.status} onValueChange={(value) => changeTableStatus(table.id, value, { stopPropagation: () => {} })}>
                    <SelectTrigger className="w-full text-xs sm:text-sm h-8 sm:h-9 lg:h-10 border-amber-300">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="libre">Libre</SelectItem>
                      <SelectItem value="ocupada">Ocupada</SelectItem>
                      <SelectItem value="en-limpieza">En Limpieza</SelectItem>
                      <SelectItem value="reservada">Reservada</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Estadísticas rápidas - Mejorado para todas las pantallas */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3 lg:gap-4 mt-4 sm:mt-6">
        <Card className="p-3 sm:p-4 lg:p-5 bg-green-50 border-green-200">
          <div className="text-center">
            <div className="text-xl sm:text-2xl lg:text-3xl font-medium text-green-700">
              {tablesState.filter(t => t.status === 'libre').length}
            </div>
            <div className="text-xs sm:text-sm lg:text-base text-green-600">Libres</div>
          </div>
        </Card>
        <Card className="p-3 sm:p-4 lg:p-5 bg-red-50 border-red-200">
          <div className="text-center">
            <div className="text-xl sm:text-2xl lg:text-3xl font-medium text-red-700">
              {tablesState.filter(t => t.status === 'ocupada').length}
            </div>
            <div className="text-xs sm:text-sm lg:text-base text-red-600">Ocupadas</div>
          </div>
        </Card>
        <Card className="p-3 sm:p-4 lg:p-5 bg-gray-50 border-gray-200">
          <div className="text-center">
            <div className="text-xl sm:text-2xl lg:text-3xl font-medium text-gray-700">
              {tablesState.filter(t => t.status === 'en-limpieza').length}
            </div>
            <div className="text-xs sm:text-sm lg:text-base text-gray-600">Limpieza</div>
          </div>
        </Card>
        <Card className="p-3 sm:p-4 lg:p-5 bg-yellow-50 border-yellow-200">
          <div className="text-center">
            <div className="text-xl sm:text-2xl lg:text-3xl font-medium text-yellow-700">
              {tablesState.filter(t => t.status === 'reservada').length}
            </div>
            <div className="text-xs sm:text-sm lg:text-base text-yellow-600">Reservadas</div>
          </div>
        </Card>
      </div>

      {/* Info del puesto */}
      <Card className="p-3 sm:p-4 bg-amber-50 border-amber-200">
        <div className="text-center">
          <div className="text-xs sm:text-sm text-amber-800 font-medium">🔥 Puesto de Barbacoa Abierto</div>
          <div className="text-xs text-amber-700 mt-1">
            Horario: 8:00 AM - 6:00 PM • Especialidad: Barbacoa de res
          </div>
        </div>
      </Card>
    </div>
  );
}