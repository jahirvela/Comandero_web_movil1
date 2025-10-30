import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { 
  Plus, 
  Edit, 
  Trash2, 
  Users, 
  Utensils,
  Clock,
  Zap,
  CheckCircle,
  AlertCircle,
  Settings,
  DollarSign
} from 'lucide-react';
import { LogoC } from '../RoleSpecificIcons';

const initialTables = [
  { id: 1, number: 1, seats: 4, status: 'libre', section: 'Área Principal', currentOrder: null },
  { id: 2, number: 2, seats: 2, status: 'ocupada', section: 'Área Principal', currentOrder: { total: 44, items: 2, time: '14:30' } },
  { id: 3, number: 3, seats: 6, status: 'reservada', section: 'Área Principal', reservation: 'Familia López - 15:00' },
  { id: 4, number: 4, seats: 4, status: 'en-limpieza', section: 'Área Lateral', currentOrder: { total: 95, items: 4, time: '13:45' } },
  { id: 5, number: 5, seats: 2, status: 'libre', section: 'Área Lateral', currentOrder: null },
  { id: 6, number: 6, seats: 8, status: 'ocupada', section: 'Área Principal', currentOrder: { total: 130, items: 6, time: '14:00' } },
  { id: 7, number: 7, seats: 4, status: 'libre', section: 'Área Lateral', currentOrder: null },
  { id: 8, number: 8, seats: 4, status: 'ocupada', section: 'Área Principal', currentOrder: { total: 66, items: 3, time: '14:15' } },
  { id: 9, number: 9, seats: 2, status: 'libre', section: 'Área Lateral', currentOrder: null },
];

const sections = ['Todos', 'Área Principal', 'Área Lateral'];

const getStatusColor = (status) => {
  switch (status) {
    case 'libre': return 'bg-green-100 text-green-800 border-green-300';
    case 'ocupada': return 'bg-red-100 text-red-800 border-red-300';
    case 'reservada': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    case 'en-limpieza': return 'bg-orange-100 text-orange-800 border-orange-300';
    default: return 'bg-gray-100 text-gray-800 border-gray-300';
  }
};

const getStatusText = (status) => {
  switch (status) {
    case 'libre': return 'Libre';
    case 'ocupada': return 'Ocupada';
    case 'reservada': return 'Reservada';
    case 'en-limpieza': return 'En Limpieza';
    default: return 'Desconocido';
  }
};

export function TableManagement() {
  const [tables, setTables] = useState(initialTables);
  const [selectedSection, setSelectedSection] = useState('Todos');
  const [editingTable, setEditingTable] = useState(null);
  const [newTable, setNewTable] = useState({ number: '', seats: '', section: 'Área Principal' });

  const filteredTables = selectedSection === 'Todos' 
    ? tables 
    : tables.filter(table => table.section === selectedSection);

  const handleAddTable = () => {
    const nextNumber = Math.max(...tables.map(t => t.number)) + 1;
    const table = {
      id: Date.now(),
      number: parseInt(newTable.number) || nextNumber,
      seats: parseInt(newTable.seats),
      status: 'libre',
      section: newTable.section,
      currentOrder: null
    };
    setTables([...tables, table]);
    setNewTable({ number: '', seats: '', section: 'Área Principal' });
  };

  const handleUpdateTable = () => {
    setTables(tables.map(table => 
      table.id === editingTable.id ? editingTable : table
    ));
    setEditingTable(null);
  };

  const handleDeleteTable = (id) => {
    setTables(tables.filter(table => table.id !== id));
  };

  const handleStatusChange = (tableId, newStatus) => {
    setTables(tables.map(table => 
      table.id === tableId 
        ? { ...table, status: newStatus, currentOrder: newStatus === 'libre' ? null : table.currentOrder }
        : table
    ));
  };

  const stats = {
    total: tables.length,
    libre: tables.filter(t => t.status === 'libre').length,
    ocupada: tables.filter(t => t.status === 'ocupada').length,
    reservada: tables.filter(t => t.status === 'reservada').length,
    'en-limpieza': tables.filter(t => t.status === 'en-limpieza').length,
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 bg-white rounded-lg flex items-center justify-center shadow-md border border-amber-200">
            <LogoC size={40} />
          </div>
          <div>
            <h1 className="text-2xl font-medium text-amber-900">
              Gestión de Mesas
            </h1>
            <p className="text-amber-700">Administra las mesas del puesto de barbacoa</p>
          </div>
        </div>
        
        <Dialog>
          <DialogTrigger asChild>
            <Button className="bg-amber-600 hover:bg-amber-700 text-white">
              <Plus className="h-4 w-4 mr-2" />
              Agregar Mesa
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="text-amber-900">Agregar Nueva Mesa</DialogTitle>
              <DialogDescription className="text-amber-700">
                Crea una nueva mesa para el puesto de barbacoa
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label htmlFor="number" className="text-amber-900">Número de Mesa</Label>
                <Input
                  id="number"
                  type="number"
                  placeholder="Ej: 10"
                  value={newTable.number}
                  onChange={(e) => setNewTable({...newTable, number: e.target.value})}
                  className="border-amber-200 focus:border-amber-500"
                />
              </div>
              <div>
                <Label htmlFor="seats" className="text-amber-900">Número de Asientos</Label>
                <Input
                  id="seats"
                  type="number"
                  placeholder="Ej: 4"
                  value={newTable.seats}
                  onChange={(e) => setNewTable({...newTable, seats: e.target.value})}
                  className="border-amber-200 focus:border-amber-500"
                />
              </div>
              <div>
                <Label htmlFor="section" className="text-amber-900">Sección</Label>
                <Select value={newTable.section} onValueChange={(value) => setNewTable({...newTable, section: value})}>
                  <SelectTrigger className="border-amber-200 focus:border-amber-500">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Área Principal">Área Principal</SelectItem>
                    <SelectItem value="Área Lateral">Área Lateral</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <Button onClick={handleAddTable} className="w-full bg-amber-600 hover:bg-amber-700">
                Crear Mesa
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Estadísticas */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <Card className="border-amber-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-amber-900">{stats.total}</div>
            <div className="text-sm text-amber-700">Total Mesas</div>
          </CardContent>
        </Card>
        <Card className="border-green-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-green-700">{stats.libre}</div>
            <div className="text-sm text-green-600">🟢 Libres</div>
          </CardContent>
        </Card>
        <Card className="border-red-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-red-700">{stats.ocupada}</div>
            <div className="text-sm text-red-600">🔴 Ocupadas</div>
          </CardContent>
        </Card>
        <Card className="border-yellow-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-yellow-700">{stats.reservada}</div>
            <div className="text-sm text-yellow-600">🟡 Reservadas</div>
          </CardContent>
        </Card>
        <Card className="border-orange-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-orange-700">{stats['en-limpieza']}</div>
            <div className="text-sm text-orange-600">🟠 En Limpieza</div>
          </CardContent>
        </Card>
      </div>

      {/* Filtros */}
      <div className="flex gap-2 flex-wrap">
        {sections.map(section => (
          <Button
            key={section}
            variant={selectedSection === section ? "default" : "outline"}
            size="sm"
            onClick={() => setSelectedSection(section)}
            className={selectedSection === section 
              ? "bg-amber-600 hover:bg-amber-700 text-white" 
              : "border-amber-300 text-amber-700 hover:bg-amber-100"
            }
          >
            {section}
          </Button>
        ))}
      </div>

      {/* Lista de mesas */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredTables.map(table => (
          <Card key={table.id} className={`${getStatusColor(table.status)} border-2`}>
            <CardHeader>
              <CardTitle className="flex justify-between items-center">
                <span>Mesa {table.number}</span>
                <Badge className={getStatusColor(table.status)}>
                  {getStatusText(table.status)}
                </Badge>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1">
                  <Users className="h-4 w-4" />
                  {table.seats} asientos
                </span>
                <span className="text-sm text-muted-foreground">{table.section}</span>
              </div>
              
              {table.currentOrder && (
                <div className="p-2 bg-white/50 rounded border">
                  <div className="flex justify-between items-center text-sm">
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      {table.currentOrder.time}
                    </span>
                    <span className="flex items-center gap-1">
                      <DollarSign className="h-3 w-3" />
                      ${table.currentOrder.total}
                    </span>
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {table.currentOrder.items} artículos
                  </div>
                </div>
              )}

              {table.reservation && (
                <div className="p-2 bg-yellow-50 rounded border border-yellow-200">
                  <div className="text-sm font-medium text-yellow-800">
                    Reserva: {table.reservation}
                  </div>
                </div>
              )}

              <div className="flex gap-2">
                <Select value={table.status} onValueChange={(value) => handleStatusChange(table.id, value)}>
                  <SelectTrigger className="flex-1">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="libre">Libre</SelectItem>
                    <SelectItem value="ocupada">Ocupada</SelectItem>
                    <SelectItem value="reservada">Reservada</SelectItem>
                    <SelectItem value="en-limpieza">En Limpieza</SelectItem>
                  </SelectContent>
                </Select>
                
                <Dialog>
                  <DialogTrigger asChild>
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => setEditingTable(table)}
                      className="border-amber-300 text-amber-700 hover:bg-amber-100"
                    >
                      <Edit className="h-4 w-4" />
                    </Button>
                  </DialogTrigger>
                  {editingTable && (
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle className="text-amber-900">Editar Mesa {editingTable.number}</DialogTitle>
                        <DialogDescription className="text-amber-700">
                          Modifica la configuración de esta mesa
                        </DialogDescription>
                      </DialogHeader>
                      <div className="space-y-4">
                        <div>
                          <Label className="text-amber-900">Número de Mesa</Label>
                          <Input
                            type="number"
                            value={editingTable.number}
                            onChange={(e) => setEditingTable({...editingTable, number: parseInt(e.target.value)})}
                            className="border-amber-200 focus:border-amber-500"
                          />
                        </div>
                        <div>
                          <Label className="text-amber-900">Asientos</Label>
                          <Input
                            type="number"
                            value={editingTable.seats}
                            onChange={(e) => setEditingTable({...editingTable, seats: parseInt(e.target.value)})}
                            className="border-amber-200 focus:border-amber-500"
                          />
                        </div>
                        <div>
                          <Label className="text-amber-900">Sección</Label>
                          <Select value={editingTable.section} onValueChange={(value) => setEditingTable({...editingTable, section: value})}>
                            <SelectTrigger className="border-amber-200 focus:border-amber-500">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="Área Principal">Área Principal</SelectItem>
                              <SelectItem value="Área Lateral">Área Lateral</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>
                        <Button onClick={handleUpdateTable} className="w-full bg-amber-600 hover:bg-amber-700">
                          Guardar Cambios
                        </Button>
                      </div>
                    </DialogContent>
                  )}
                </Dialog>
                
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={() => handleDeleteTable(table.id)}
                  className="border-red-300 text-red-600 hover:bg-red-50"
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}