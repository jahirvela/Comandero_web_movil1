import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Separator } from '../ui/separator';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { AlertDialog, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger, AlertDialogCancel, AlertDialogAction } from '../ui/alert-dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from '../ui/sheet';
import { 
  Eye, CheckCircle, AlertCircle, X, FileText, Download, 
  Filter, Search, Calendar, DollarSign, CreditCard, Coins 
} from 'lucide-react';
import { toast } from 'sonner@2.0.3';
import { useNotifications } from '../NotificationContext';
import { 
  mockCashierClosures, 
  getCashierClosuresByPreset, 
  calculateCashierSummaryTotals,
  type CashierClosureRecord,
  type AuditLogEntry
} from './cash-close/mockData';

interface CashierClosureManagementProps {
  userRole?: 'admin';
}

export function CashierClosureManagement({ userRole = 'admin' }: CashierClosureManagementProps) {
  // Contexto de notificaciones
  const { addNotification } = useNotifications();
  
  // Estados principales
  const [currentPreset, setCurrentPreset] = useState('today');
  const [statusFilter, setStatusFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [filteredClosures, setFilteredClosures] = useState<CashierClosureRecord[]>([]);
  const [selectedClosure, setSelectedClosure] = useState<CashierClosureRecord | null>(null);
  const [isDetailPanelOpen, setIsDetailPanelOpen] = useState(false);
  const [isVerificationDialogOpen, setIsVerificationDialogOpen] = useState(false);
  const [isClarificationDialogOpen, setIsClarificationDialogOpen] = useState(false);
  const [clarificationReason, setClarificationReason] = useState('');
  
  // Estados de paginación
  const [currentPage, setCurrentPage] = useState(1);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // Detectar si es mobile
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  // Actualizar datos filtrados cuando cambian los filtros
  useEffect(() => {
    let closures = getCashierClosuresByPreset(currentPreset, statusFilter);
    
    // Filtrar por búsqueda de cajero
    if (searchTerm) {
      closures = closures.filter(closure => 
        closure.usuario.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    
    setFilteredClosures(closures);
    setCurrentPage(1);
  }, [currentPreset, statusFilter, searchTerm]);

  // Calcular paginación
  const totalPages = Math.ceil(filteredClosures.length / rowsPerPage);
  const startIndex = (currentPage - 1) * rowsPerPage;
  const paginatedClosures = filteredClosures.slice(startIndex, startIndex + rowsPerPage);

  // Calcular totales para el resumen
  const summaryTotals = calculateCashierSummaryTotals(filteredClosures);

  // Handlers
  const handleSelectClosure = (closure: CashierClosureRecord) => {
    setSelectedClosure(closure);
    setIsDetailPanelOpen(true);
  };

  const handleMarkVerified = async () => {
    if (!selectedClosure) return;
    
    try {
      // Simular llamada a API
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Actualizar estado en mock data
      const closureIndex = mockCashierClosures.findIndex(c => c.id === selectedClosure.id);
      if (closureIndex !== -1) {
        mockCashierClosures[closureIndex].estado = 'Verificado';
        mockCashierClosures[closureIndex].auditLog.push({
          id: `log_${Date.now()}`,
          timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
          action: 'verificado',
          usuario: 'Admin',
          mensaje: `Verificado por Admin — ${new Date().toISOString().slice(0, 19).replace('T', ' ')}`
        });
        
        // Actualizar estado local
        setFilteredClosures(prev => 
          prev.map(c => c.id === selectedClosure.id ? 
            { ...c, estado: 'Verificado' as const } : c
          )
        );
      }
      
      toast("Cierre verificado");
      setIsVerificationDialogOpen(false);
      setIsDetailPanelOpen(false);
    } catch (error) {
      toast("Error al verificar cierre");
    }
  };

  const handleRequestClarification = async () => {
    if (!selectedClosure || !clarificationReason.trim()) return;
    
    try {
      // Simular llamada a API
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Actualizar estado en mock data
      const closureIndex = mockCashierClosures.findIndex(c => c.id === selectedClosure.id);
      if (closureIndex !== -1) {
        mockCashierClosures[closureIndex].estado = 'Aclaración requerida';
        mockCashierClosures[closureIndex].auditLog.push({
          id: `log_${Date.now()}`,
          timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
          action: 'aclaración_solicitada',
          usuario: 'Admin',
          mensaje: 'Aclaración solicitada por Admin',
          motivo: clarificationReason
        });
        
        // Actualizar estado local
        setFilteredClosures(prev => 
          prev.map(c => c.id === selectedClosure.id ? 
            { ...c, estado: 'Aclaración requerida' as const } : c
          )
        );
        
        // Enviar notificación al cajero
        addNotification({
          type: 'cash_close_clarification',
          title: 'Aclaración solicitada para cierre',
          message: `Aclaración solicitada para cierre del ${selectedClosure.fecha.split(' ')[0]} — motivo: ${clarificationReason}`,
          targetRole: 'cajero',
          targetUser: selectedClosure.usuario,
          fromUser: 'Admin',
          fromRole: 'admin',
          closureId: selectedClosure.id,
          clarificationReason: clarificationReason,
          priority: 'normal'
        });
      }
      
      toast("Solicitud enviada al cajero");
      setIsClarificationDialogOpen(false);
      setClarificationReason('');
      setIsDetailPanelOpen(false);
    } catch (error) {
      toast("Error al enviar solicitud");
    }
  };

  const handleExportCSV = () => {
    toast("Exportación lista");
    console.log('Exportando CSV con datos:', filteredClosures);
  };

  const handlePrintDetail = (closureId: string) => {
    console.log('Imprimiendo detalle del cierre:', closureId);
    toast("Imprimiendo detalle del cierre");
  };

  const getStatusBadge = (estado: string) => {
    switch (estado) {
      case 'Verificado':
        return (
          <Badge className="bg-green-100 text-green-800 border-green-300">
            <CheckCircle className="h-3 w-3 mr-1" />
            Verificado
          </Badge>
        );
      case 'Aclaración requerida':
        return (
          <Badge className="bg-red-100 text-red-800 border-red-300">
            <AlertCircle className="h-3 w-3 mr-1" />
            Aclaración requerida
          </Badge>
        );
      default:
        return (
          <Badge className="bg-amber-100 text-amber-800 border-amber-300">
            <AlertCircle className="h-3 w-3 mr-1" />
            Pendiente verificación
          </Badge>
        );
    }
  };

  const formatCurrency = (amount: number) => `$${amount.toFixed(2)}`;

  const DetailPanel = () => {
    if (!selectedClosure) return null;

    const Content = () => (
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg text-amber-900">
              Detalle del cierre — {selectedClosure.fecha.split(' ')[0]}
            </h3>
            <p className="text-sm text-amber-700">
              {selectedClosure.usuario} • {selectedClosure.fecha}
            </p>
          </div>
          {getStatusBadge(selectedClosure.estado)}
        </div>

        {/* Campos enviados por el cajero */}
        <Card className="border-amber-200">
          <CardHeader>
            <CardTitle className="text-amber-900">Información del Cierre</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm text-amber-700">Efectivo contado hoy:</label>
                <div className="text-lg text-amber-900">{formatCurrency(selectedClosure.efectivoContado)}</div>
              </div>
              <div className="space-y-2">
                <label className="text-sm text-amber-700">Total tarjeta:</label>
                <div className="text-lg text-amber-900">{formatCurrency(selectedClosure.totalTarjeta)}</div>
              </div>
              <div className="space-y-2">
                <label className="text-sm text-amber-700">Otros ingresos:</label>
                <div className="text-lg text-amber-900">{formatCurrency(selectedClosure.otrosIngresos)}</div>
                {selectedClosure.otrosIngresosTexto && (
                  <div className="text-sm text-amber-600 italic">
                    {selectedClosure.otrosIngresosTexto}
                  </div>
                )}
              </div>
              <div className="space-y-2">
                <label className="text-sm text-amber-700">Total declarado:</label>
                <div className="text-xl text-amber-900">{formatCurrency(selectedClosure.totalDeclarado)}</div>
              </div>
            </div>
            
            {selectedClosure.notaCajero && (
              <div className="space-y-2">
                <label className="text-sm text-amber-700">Nota del cajero:</label>
                <div className="p-3 bg-amber-50 rounded-md border border-amber-200">
                  <p className="text-sm text-amber-800">{selectedClosure.notaCajero}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Historial de auditoría */}
        <Card className="border-amber-200">
          <CardHeader>
            <CardTitle className="text-amber-900">Historial de Auditoría</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {selectedClosure.auditLog.map((entry) => (
                <div key={entry.id} className="flex items-start space-x-3 p-3 bg-gray-50 rounded-md">
                  <div className="flex-1">
                    <p className="text-sm text-gray-900">{entry.mensaje}</p>
                    {entry.motivo && (
                      <p className="text-xs text-gray-600 mt-1">Motivo: {entry.motivo}</p>
                    )}
                    <p className="text-xs text-gray-500 mt-1">{entry.timestamp}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Botones de acción */}
        <div className="flex flex-col sm:flex-row gap-3">
          <Button
            variant="outline"
            onClick={() => handlePrintDetail(selectedClosure.id)}
            className="border-amber-300 text-amber-700 hover:bg-amber-50"
          >
            <FileText className="h-4 w-4 mr-2" />
            Imprimir detalle
          </Button>

          {selectedClosure.estado === 'Pendiente verificación' && (
            <>
              <Button
                variant="outline"
                onClick={() => setIsClarificationDialogOpen(true)}
                className="border-orange-300 text-orange-700 hover:bg-orange-50"
              >
                <AlertCircle className="h-4 w-4 mr-2" />
                Solicitar aclaración
              </Button>
              <Button
                onClick={() => setIsVerificationDialogOpen(true)}
                className="bg-green-600 hover:bg-green-700 text-white"
              >
                <CheckCircle className="h-4 w-4 mr-2" />
                Marcar verificado
              </Button>
            </>
          )}
        </div>
      </div>
    );

    if (isMobile) {
      return (
        <Sheet open={isDetailPanelOpen} onOpenChange={setIsDetailPanelOpen}>
          <SheetContent side="bottom" className="h-[90vh] overflow-y-auto">
            <SheetHeader>
              <SheetTitle>Detalle del cierre</SheetTitle>
              <SheetDescription>
                Información detallada del cierre enviado por el cajero
              </SheetDescription>
            </SheetHeader>
            <div className="mt-6">
              <Content />
            </div>
          </SheetContent>
        </Sheet>
      );
    }

    return (
      <Dialog open={isDetailPanelOpen} onOpenChange={setIsDetailPanelOpen}>
        <DialogContent className="sm:max-w-2xl lg:max-w-3xl xl:max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Detalle del cierre</DialogTitle>
            <DialogDescription>
              Información detallada del cierre enviado por el cajero
            </DialogDescription>
          </DialogHeader>
          <Content />
        </DialogContent>
      </Dialog>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl text-amber-900 mb-2">
          Admin — Revisar Cierres Enviados por Cajeros
        </h1>
        <p className="text-amber-700">
          Gestión y verificación de cierres de caja enviados por los cajeros
        </p>
      </div>

      {/* Filtros */}
      <Card className="border-amber-200">
        <CardContent className="p-4">
          <div className="flex flex-col lg:flex-row gap-4">
            <div className="flex-1">
              <label className="text-sm text-amber-700 mb-2 block">Rango de fechas</label>
              <Select value={currentPreset} onValueChange={setCurrentPreset}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="today">Hoy</SelectItem>
                  <SelectItem value="yesterday">Ayer</SelectItem>
                  <SelectItem value="last-week">Última semana</SelectItem>
                  <SelectItem value="current-month">Mes actual</SelectItem>
                  <SelectItem value="all">Todos</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="flex-1">
              <label className="text-sm text-amber-700 mb-2 block">Estado</label>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todos los estados</SelectItem>
                  <SelectItem value="Pendiente verificación">Pendiente verificación</SelectItem>
                  <SelectItem value="Verificado">Verificado</SelectItem>
                  <SelectItem value="Aclaración requerida">Aclaración requerida</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="flex-1">
              <label className="text-sm text-amber-700 mb-2 block">Buscar por cajero</label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-amber-600" />
                <Input
                  placeholder="Buscar cajero..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            
            <div className="flex gap-2">
              <Button
                variant="outline"
                onClick={handleExportCSV}
                className="border-amber-300 text-amber-700 hover:bg-amber-50"
              >
                <Download className="h-4 w-4 mr-2" />
                Exportar CSV
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Cards de resumen */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border-amber-200">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-amber-600 mb-1">Total Declarado</p>
                <p className="text-lg text-amber-900">{formatCurrency(summaryTotals.totalDeclarado)}</p>
              </div>
              <DollarSign className="h-5 w-5 text-amber-600 opacity-60" />
            </div>
          </CardContent>
        </Card>
        
        <Card className="border-green-200 bg-green-50">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-green-600 mb-1">Efectivo Contado</p>
                <p className="text-lg text-green-800">{formatCurrency(summaryTotals.efectivoContado)}</p>
              </div>
              <Coins className="h-5 w-5 text-green-600 opacity-60" />
            </div>
          </CardContent>
        </Card>
        
        <Card className="border-blue-200 bg-blue-50">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-blue-600 mb-1">Total Tarjeta</p>
                <p className="text-lg text-blue-800">{formatCurrency(summaryTotals.totalTarjeta)}</p>
              </div>
              <CreditCard className="h-5 w-5 text-blue-600 opacity-60" />
            </div>
          </CardContent>
        </Card>
        
        <Card className="border-amber-200">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-amber-600 mb-1">Cierres Totales</p>
                <p className="text-lg text-amber-900">{summaryTotals.cantidadCierres}</p>
                <div className="flex text-xs text-amber-600 mt-1 space-x-2">
                  <span>✓ {summaryTotals.verificados}</span>
                  <span>⏳ {summaryTotals.pendientes}</span>
                  <span>⚠ {summaryTotals.aclaraciones}</span>
                </div>
              </div>
              <FileText className="h-5 w-5 text-amber-600 opacity-60" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabla de cierres */}
      <Card className="border-amber-200">
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Fecha</TableHead>
                  <TableHead>Cajero</TableHead>
                  <TableHead className="text-right">Efectivo contado</TableHead>
                  <TableHead className="text-right">Total tarjeta</TableHead>
                  <TableHead className="text-right">Otros ingresos</TableHead>
                  <TableHead className="text-right">Total declarado</TableHead>
                  <TableHead>Estado</TableHead>
                  <TableHead>Acciones</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedClosures.map((closure) => (
                  <TableRow key={closure.id}>
                    <TableCell className="font-mono text-sm">
                      {closure.fecha}
                    </TableCell>
                    <TableCell>{closure.usuario}</TableCell>
                    <TableCell className="text-right">
                      {formatCurrency(closure.efectivoContado)}
                    </TableCell>
                    <TableCell className="text-right">
                      {formatCurrency(closure.totalTarjeta)}
                    </TableCell>
                    <TableCell className="text-right">
                      {formatCurrency(closure.otrosIngresos)}
                    </TableCell>
                    <TableCell className="text-right">
                      <span className="font-medium">{formatCurrency(closure.totalDeclarado)}</span>
                    </TableCell>
                    <TableCell>
                      {getStatusBadge(closure.estado)}
                    </TableCell>
                    <TableCell>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleSelectClosure(closure)}
                        className="border-amber-300 text-amber-700 hover:bg-amber-50"
                      >
                        <Eye className="h-4 w-4 mr-1" />
                        Ver detalle
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* Panel de detalle */}
      <DetailPanel />

      {/* Dialog de confirmación de verificación */}
      <AlertDialog open={isVerificationDialogOpen} onOpenChange={setIsVerificationDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar verificación del cierre</AlertDialogTitle>
            <AlertDialogDescription>
              ¿Confirmar verificación del cierre enviado por {selectedClosure?.usuario}?
              Esta acción marcará el cierre como verificado y no se podrá deshacer.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleMarkVerified}
              className="bg-green-600 hover:bg-green-700"
            >
              Confirmar verificación
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Dialog de solicitud de aclaración */}
      <Dialog open={isClarificationDialogOpen} onOpenChange={setIsClarificationDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Solicitar aclaración</DialogTitle>
            <DialogDescription>
              Describe la aclaración que necesitas del cajero {selectedClosure?.usuario}.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium">Motivo de la aclaración</label>
              <Textarea
                placeholder="Describe la aclaración solicitada..."
                value={clarificationReason}
                onChange={(e) => setClarificationReason(e.target.value)}
                className="mt-1"
                rows={4}
              />
            </div>
          </div>
          <div className="flex justify-end gap-3">
            <Button 
              variant="outline" 
              onClick={() => {
                setIsClarificationDialogOpen(false);
                setClarificationReason('');
              }}
            >
              Cancelar
            </Button>
            <Button 
              onClick={handleRequestClarification}
              disabled={!clarificationReason.trim()}
              className="bg-orange-600 hover:bg-orange-700"
            >
              Enviar solicitud
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}