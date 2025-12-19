import React, { useState, useEffect } from 'react';
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
  Filter,
  Loader2
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
import { ticketsAPI } from '../../services/api';

interface Ticket {
  id: string;
  ordenId: number;
  ordenIds?: number[];
  tableNumber: number | null;
  mesaCodigo?: string | null;
  total: number;
  status: 'pending' | 'printed' | 'delivered';
  printedBy: string | null;
  printedAt: string | null;
  paymentMethod: string | null;
  paymentReference?: string | null; // Referencia del pago (incluye info de débito/crédito)
  cashierName: string | null;
  waiterName: string | null;
  createdAt: string;
  isGrouped?: boolean;
}

export function TicketManagement() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);

  // Cargar tickets del backend
  useEffect(() => {
    loadTickets();
  }, []);

  const loadTickets = async () => {
    try {
      setLoading(true);
      const data = await ticketsAPI.getTickets();
      setTickets(data || []);
    } catch (error) {
      console.error('Error al cargar tickets:', error);
      alert('Error al cargar los tickets. Por favor, recarga la página.');
    } finally {
      setLoading(false);
    }
  };

  // Función para obtener el texto del método de pago con información de débito/crédito
  const getPaymentMethodText = (ticket: Ticket): string => {
    // Priorizar paymentMethod que ya viene procesado del backend
    if (ticket.paymentMethod) {
      // Si el método de pago ya contiene información de débito/crédito, usarlo directamente
      if (ticket.paymentMethod.includes('Tarjeta Débito') || ticket.paymentMethod.includes('Tarjeta Crédito')) {
        return ticket.paymentMethod;
      }
      // Si es "Tarjeta" genérico y hay referencia, intentar extraer info de la referencia
      if (ticket.paymentMethod.toLowerCase().includes('tarjeta') && ticket.paymentReference) {
        if (ticket.paymentReference.includes('Tarjeta Débito')) {
          return 'Tarjeta Débito';
        } else if (ticket.paymentReference.includes('Tarjeta Crédito')) {
          return 'Tarjeta Crédito';
        }
      }
      return ticket.paymentMethod;
    }
    
    // Si no hay paymentMethod pero hay referencia, intentar extraer de la referencia
    if (ticket.paymentReference) {
      if (ticket.paymentReference.includes('Tarjeta Débito')) {
        return 'Tarjeta Débito';
      } else if (ticket.paymentReference.includes('Tarjeta Crédito')) {
        return 'Tarjeta Crédito';
      } else if (ticket.paymentReference.toLowerCase().includes('tarjeta')) {
        return 'Tarjeta';
      }
    }
    
    return 'N/A';
  };

  // Función para obtener el color del badge según el método de pago
  const getPaymentMethodColor = (ticket: Ticket): string => {
    const methodText = getPaymentMethodText(ticket).toLowerCase();
    
    if (methodText.includes('débito') || methodText.includes('debito')) {
      return 'bg-blue-100 text-blue-800 border-blue-300';
    } else if (methodText.includes('crédito') || methodText.includes('credito')) {
      return 'bg-purple-100 text-purple-800 border-purple-300';
    } else if (methodText.includes('tarjeta')) {
      return 'bg-indigo-100 text-indigo-800 border-indigo-300';
    } else if (methodText.includes('efectivo')) {
      return 'bg-green-100 text-green-800 border-green-300';
    }
    
    return 'bg-gray-100 text-gray-800 border-gray-300';
  };

  const filteredTickets = tickets.filter(ticket => {
    const matchesSearch = 
      ticket.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (ticket.tableNumber?.toString() || '').includes(searchTerm) ||
      (ticket.printedBy?.toLowerCase() || '').includes(searchTerm.toLowerCase()) ||
      (ticket.paymentMethod?.toLowerCase() || '').includes(searchTerm.toLowerCase()) ||
      (ticket.cashierName?.toLowerCase() || '').includes(searchTerm.toLowerCase());
    
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

  const handleMarkAsDelivered = async (ticket: Ticket) => {
    // Esta funcionalidad podría requerir un endpoint adicional en el backend
    // Por ahora, solo actualizamos el estado local
    setTickets(prev => prev.map(t => 
      t.id === ticket.id 
        ? { ...t, status: 'delivered' as const }
        : t
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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'printed':
        return 'bg-blue-100 text-blue-800 border-blue-300';
      case 'delivered':
        return 'bg-green-100 text-green-800 border-green-300';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'printed':
        return 'Impreso';
      case 'delivered':
        return 'Entregado';
      default:
        return status;
    }
  };

  const totalTickets = tickets.length;
  const totalAmount = tickets.reduce((sum, ticket) => sum + ticket.total, 0);
  const pendingTickets = tickets.filter(t => t.status === 'pending').length;
  const printedTickets = tickets.filter(t => t.status === 'printed').length;

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
            <SelectItem value="pending">Pendiente</SelectItem>
            <SelectItem value="printed">Impreso</SelectItem>
            <SelectItem value="delivered">Entregado</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Tabla de tickets */}
      <Card className="border-amber-200">
        <CardHeader>
          <CardTitle className="text-amber-900">Lista de Tickets</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8 text-amber-700">
              <Loader2 className="h-8 w-8 mx-auto mb-4 text-amber-400 animate-spin" />
              <p>Cargando tickets...</p>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-amber-900">ID</TableHead>
                    <TableHead className="text-amber-900">Mesa</TableHead>
                    <TableHead className="text-amber-900">Total</TableHead>
                    <TableHead className="text-amber-900">Método de Pago</TableHead>
                    <TableHead className="text-amber-900">Estado</TableHead>
                    <TableHead className="text-amber-900">Cajero</TableHead>
                    <TableHead className="text-amber-900">Impreso por</TableHead>
                    <TableHead className="text-amber-900">Fecha/Hora</TableHead>
                    <TableHead className="text-amber-900">Acciones</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredTickets.map((ticket) => (
                    <TableRow key={ticket.id}>
                      <TableCell className="font-medium text-amber-900">{ticket.id}</TableCell>
                      <TableCell className="text-amber-900">
                        {ticket.tableNumber ? `Mesa ${ticket.tableNumber}` : (ticket.mesaCodigo || 'N/A')}
                        {ticket.isGrouped && (
                          <Badge className="ml-2 bg-purple-100 text-purple-800 border-purple-300 text-xs">
                            Agrupada
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="font-medium text-green-600">${ticket.total.toFixed(2)}</TableCell>
                      <TableCell>
                        <Badge className={getPaymentMethodColor(ticket)}>
                          {getPaymentMethodText(ticket)}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge className={getStatusColor(ticket.status)}>
                          {getStatusText(ticket.status)}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-amber-700">{ticket.cashierName || 'N/A'}</TableCell>
                      <TableCell className="text-amber-700">{ticket.printedBy || 'N/A'}</TableCell>
                      <TableCell className="text-amber-700">
                        {ticket.printedAt 
                          ? new Date(ticket.printedAt).toLocaleString('es-MX', {
                              dateStyle: 'short',
                              timeStyle: 'short'
                            })
                          : (ticket.createdAt 
                              ? new Date(ticket.createdAt).toLocaleString('es-MX', {
                                  dateStyle: 'short',
                                  timeStyle: 'short'
                                })
                              : 'N/A')}
                      </TableCell>
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
                                    <p className="font-medium">{ticket.tableNumber ? `Mesa ${ticket.tableNumber}` : ticket.mesaCodigo || 'N/A'}</p>
                                  </div>
                                  <div>
                                    <Label className="text-amber-900">Total:</Label>
                                    <p className="font-medium text-green-600">${ticket.total.toFixed(2)}</p>
                                  </div>
                                  <div>
                                    <Label className="text-amber-900">Método de Pago:</Label>
                                    <p className="font-medium">{getPaymentMethodText(ticket)}</p>
                                    {ticket.paymentReference && ticket.paymentReference.includes(' - ') && (
                                      <p className="text-xs text-amber-600 mt-1">
                                        {ticket.paymentReference.split(' - ').slice(1).join(' - ')}
                                      </p>
                                    )}
                                  </div>
                                  <div>
                                    <Label className="text-amber-900">Estado:</Label>
                                    <p className="font-medium">{getStatusText(ticket.status)}</p>
                                  </div>
                                  <div>
                                    <Label className="text-amber-900">Cajero:</Label>
                                    <p className="font-medium">{ticket.cashierName || 'N/A'}</p>
                                  </div>
                                  <div>
                                    <Label className="text-amber-900">Mesero:</Label>
                                    <p className="font-medium">{ticket.waiterName || 'N/A'}</p>
                                  </div>
                                </div>
                                {ticket.isGrouped && ticket.ordenIds && ticket.ordenIds.length > 1 && (
                                  <div>
                                    <Label className="text-amber-900">Órdenes Agrupadas:</Label>
                                    <p className="font-medium text-sm">{ticket.ordenIds.map(id => `ORD-${String(id).padStart(6, '0')}`).join(', ')}</p>
                                  </div>
                                )}
                              </div>
                            </DialogContent>
                          </Dialog>
                          
                          {ticket.status === 'pending' && (
                            <Button 
                              variant="outline" 
                              size="sm"
                              onClick={() => handlePrintTicket(ticket)}
                              className="border-blue-300 text-blue-700 hover:bg-blue-100"
                            >
                              <Printer className="h-4 w-4" />
                            </Button>
                          )}
                          
                          {ticket.status === 'printed' && (
                            <>
                              <Button 
                                variant="outline" 
                                size="sm"
                                onClick={() => handlePrintTicket(ticket)}
                                className="border-blue-300 text-blue-700 hover:bg-blue-100"
                              >
                                <Printer className="h-4 w-4" />
                              </Button>
                              <Button 
                                variant="outline" 
                                size="sm"
                                onClick={() => handleMarkAsDelivered(ticket)}
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
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}