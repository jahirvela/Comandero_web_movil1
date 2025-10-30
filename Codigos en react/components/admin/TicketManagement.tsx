import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { 
  FileText, 
  Printer, 
  Check, 
  Download, 
  Search,
  Calendar,
  DollarSign,
  Eye,
  Filter
} from 'lucide-react';
import { 
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogDescription,
} from '../ui/dialog';
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../ui/table';

// Datos de ejemplo para tickets de cobro
const mockTickets = [
  {
    id: 'T001',
    accountId: 'ACC001',
    tableNumber: 5,
    total: 280,
    status: 'Impreso',
    printedBy: 'Juan Pérez (Cajero)',
    printedAt: '2024-01-15 14:30',
    items: [
      { name: 'Taco de Barbacoa', quantity: 4, price: 88 },
      { name: 'Mix Barbacoa', quantity: 2, price: 190 },
      { name: 'Agua de Horchata', quantity: 1, price: 18 }
    ]
  },
  {
    id: 'T002',
    accountId: 'ACC002',
    tableNumber: 3,
    total: 155,
    status: 'Pendiente',
    printedBy: '',
    printedAt: '',
    items: [
      { name: 'Taco de Maciza', quantity: 3, price: 75 },
      { name: 'Consomé', quantity: 2, price: 70 },
      { name: 'Tortillas', quantity: 1, price: 15 }
    ]
  },
  {
    id: 'T003',
    accountId: 'ACC003',
    tableNumber: 8,
    total: 425,
    status: 'Entregado',
    printedBy: 'María García (Capitán)',
    printedAt: '2024-01-15 13:15',
    deliveredAt: '2024-01-15 13:45',
    items: [
      { name: 'Costilla en Salsa', quantity: 2, price: 260 },
      { name: 'Orden de Barbacoa', quantity: 1, price: 110 },
      { name: 'Cerveza Nacional', quantity: 2, price: 50 }
    ]
  },
  {
    id: 'T004',
    accountId: 'ACC004',
    tableNumber: 12,
    total: 95,
    status: 'Impreso',
    printedBy: 'Ana López (Admin)',
    printedAt: '2024-01-15 15:00',
    items: [
      { name: 'Mix Barbacoa', quantity: 1, price: 95 }
    ]
  },
  {
    id: 'T005',
    accountId: 'ACC005',
    tableNumber: 2,
    total: 180,
    status: 'Pendiente',
    printedBy: '',
    printedAt: '',
    items: [
      { name: 'Taco de Costilla', quantity: 3, price: 84 },
      { name: 'Frijoles Charros', quantity: 2, price: 50 },
      { name: 'Agua de Jamaica', quantity: 2, price: 36 }
    ]
  }
];

export function TicketManagement() {
  const [tickets, setTickets] = useState(mockTickets);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedTicket, setSelectedTicket] = useState(null);

  const filteredTickets = tickets.filter(ticket => {
    const matchesSearch = 
      ticket.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.accountId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.tableNumber.toString().includes(searchTerm) ||
      ticket.printedBy.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === 'all' || ticket.status === statusFilter;
    
    return matchesSearch && matchesStatus;
  });

  const handlePrintTicket = (ticketId) => {
    const message = `¿Imprimir ticket para Mesa ${tickets.find(t => t.id === ticketId)?.tableNumber}?`;
    if (confirm(message)) {
      setTickets(prev => prev.map(ticket => 
        ticket.id === ticketId 
          ? { 
              ...ticket, 
              status: 'Impreso',
              printedBy: 'Administrador',
              printedAt: new Date().toLocaleString('es-MX')
            }
          : ticket
      ));
      alert('Ticket impreso: Mesa ' + tickets.find(t => t.id === ticketId)?.tableNumber + '. Notificación enviada al mesero.');
    }
  };

  const handleMarkAsDelivered = (ticketId) => {
    setTickets(prev => prev.map(ticket => 
      ticket.id === ticketId 
        ? { 
            ...ticket, 
            status: 'Entregado',
            deliveredAt: new Date().toLocaleString('es-MX')
          }
        : ticket
    ));
  };

  const handleExportCSV = () => {
    const csvData = tickets.map(ticket => ({
      ID: ticket.id,
      Mesa: ticket.tableNumber,
      CuentaID: ticket.accountId,
      Total: ticket.total,
      Estado: ticket.status,
      Impreso_por: ticket.printedBy,
      Fecha_Impresion: ticket.printedAt,
      Fecha_Entrega: ticket.deliveredAt || ''
    }));
    
    alert('Exportando tickets a CSV...');
    console.log('CSV Data:', csvData);
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'Pendiente':
        return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'Impreso':
        return 'bg-blue-100 text-blue-800 border-blue-300';
      case 'Entregado':
        return 'bg-green-100 text-green-800 border-green-300';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const totalTickets = tickets.length;
  const totalAmount = tickets.reduce((sum, ticket) => sum + ticket.total, 0);
  const pendingTickets = tickets.filter(t => t.status === 'Pendiente').length;
  const printedTickets = tickets.filter(t => t.status === 'Impreso').length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-medium text-amber-900 flex items-center gap-2">
            🎫 Gestión de Tickets de Cobro
          </h1>
          <p className="text-amber-700">Control y seguimiento de tickets impresos</p>
        </div>
        
        <Button 
          onClick={handleExportCSV}
          className="bg-amber-600 hover:bg-amber-700 text-white"
        >
          <Download className="h-4 w-4 mr-2" />
          Exportar CSV
        </Button>
      </div>

      {/* Estadísticas */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border-amber-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-amber-900">Total Tickets</CardTitle>
            <FileText className="h-4 w-4 text-amber-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-amber-900">{totalTickets}</div>
            <p className="text-xs text-amber-700">En el sistema</p>
          </CardContent>
        </Card>

        <Card className="border-amber-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-amber-900">Valor Total</CardTitle>
            <DollarSign className="h-4 w-4 text-amber-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">${totalAmount}</div>
            <p className="text-xs text-amber-700">Suma de todos los tickets</p>
          </CardContent>
        </Card>

        <Card className="border-amber-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-amber-900">Pendientes</CardTitle>
            <Calendar className="h-4 w-4 text-amber-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-600">{pendingTickets}</div>
            <p className="text-xs text-amber-700">Por imprimir</p>
          </CardContent>
        </Card>

        <Card className="border-amber-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-amber-900">Impresos</CardTitle>
            <Printer className="h-4 w-4 text-amber-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-600">{printedTickets}</div>
            <p className="text-xs text-amber-700">Listos para entrega</p>
          </CardContent>
        </Card>
      </div>

      {/* Filtros y búsqueda */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-amber-500 h-4 w-4" />
          <Input
            placeholder="Buscar por ID, mesa, cuenta o impreso por..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10 border-amber-200 focus:border-amber-500"
          />
        </div>
        
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-full sm:w-48 border-amber-200">
            <SelectValue placeholder="Filtrar por estado" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos los estados</SelectItem>
            <SelectItem value="Pendiente">Pendiente</SelectItem>
            <SelectItem value="Impreso">Impreso</SelectItem>
            <SelectItem value="Entregado">Entregado</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Tabla de tickets */}
      <Card className="border-amber-200">
        <CardHeader>
          <CardTitle className="text-amber-900">Lista de Tickets</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-amber-900">ID</TableHead>
                <TableHead className="text-amber-900">Mesa</TableHead>
                <TableHead className="text-amber-900">Cuenta ID</TableHead>
                <TableHead className="text-amber-900">Total</TableHead>
                <TableHead className="text-amber-900">Estado</TableHead>
                <TableHead className="text-amber-900">Impreso por</TableHead>
                <TableHead className="text-amber-900">Fecha/Hora</TableHead>
                <TableHead className="text-amber-900">Acciones</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredTickets.map((ticket) => (
                <TableRow key={ticket.id}>
                  <TableCell className="font-medium text-amber-900">{ticket.id}</TableCell>
                  <TableCell className="text-amber-900">{ticket.tableNumber}</TableCell>
                  <TableCell className="text-amber-700">{ticket.accountId}</TableCell>
                  <TableCell className="font-medium text-green-600">${ticket.total}</TableCell>
                  <TableCell>
                    <Badge className={getStatusColor(ticket.status)}>
                      {ticket.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-amber-700">{ticket.printedBy || 'N/A'}</TableCell>
                  <TableCell className="text-amber-700">{ticket.printedAt || 'N/A'}</TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => setSelectedTicket(ticket)}
                            className="border-amber-300 text-amber-700 hover:bg-amber-100"
                          >
                            <Eye className="h-4 w-4" />
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-md">
                          <DialogHeader>
                            <DialogTitle>Detalles del Ticket {ticket.id}</DialogTitle>
                            <DialogDescription>
                              Información completa del ticket de venta
                            </DialogDescription>
                          </DialogHeader>
                          <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4 text-sm">
                              <div>
                                <Label className="text-amber-900">Mesa:</Label>
                                <p className="font-medium">{ticket.tableNumber}</p>
                              </div>
                              <div>
                                <Label className="text-amber-900">Total:</Label>
                                <p className="font-medium text-green-600">${ticket.total}</p>
                              </div>
                            </div>
                            <div>
                              <Label className="text-amber-900">Productos:</Label>
                              <div className="space-y-2 mt-2">
                                {ticket.items.map((item, index) => (
                                  <div key={index} className="flex justify-between text-sm bg-amber-50 p-2 rounded">
                                    <span>{item.quantity}x {item.name}</span>
                                    <span className="font-medium">${item.price}</span>
                                  </div>
                                ))}
                              </div>
                            </div>
                          </div>
                        </DialogContent>
                      </Dialog>
                      
                      {ticket.status === 'Pendiente' && (
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => handlePrintTicket(ticket.id)}
                          className="border-blue-300 text-blue-700 hover:bg-blue-100"
                        >
                          <Printer className="h-4 w-4" />
                        </Button>
                      )}
                      
                      {ticket.status === 'Impreso' && (
                        <>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handlePrintTicket(ticket.id)}
                            className="border-blue-300 text-blue-700 hover:bg-blue-100"
                          >
                            <Printer className="h-4 w-4" />
                          </Button>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handleMarkAsDelivered(ticket.id)}
                            className="border-green-300 text-green-700 hover:bg-green-100"
                          >
                            <Check className="h-4 w-4" />
                          </Button>
                        </>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          {filteredTickets.length === 0 && (
            <div className="text-center py-8 text-amber-700">
              <FileText className="h-12 w-12 mx-auto mb-4 text-amber-400" />
              <p>No se encontraron tickets con los filtros aplicados</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}