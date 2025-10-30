import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../../ui/card';
import { Badge } from '../../ui/badge';
import { Button } from '../../ui/button';
import { Separator } from '../../ui/separator';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../../ui/table';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from '../../ui/sheet';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../../ui/dialog';
import { X, CheckCircle, AlertCircle, Printer, DollarSign, CreditCard, Star } from 'lucide-react';
import { toast } from 'sonner@2.0.3';
import type { ClosureRecord } from './ClosureTable';

interface Transaction {
  id: string;
  orden: string;
  mesa: string | null;
  cliente?: string;
  metodoPago: 'Efectivo' | 'Tarjeta';
  subtotal: number;
  propina: number;
  total: number;
  origen: 'Local' | 'Para llevar';
}

interface ClosureDetailPanelProps {
  closure: ClosureRecord | null;
  isOpen: boolean;
  onClose: () => void;
  onMarkVerified: (closureId: string) => void;
  onRequestClarification: (closureId: string) => void;
  onPrintDetail: (closureId: string) => void;
  isMobile?: boolean;
  userRole: 'admin' | 'cajero';
}

const mockTransactions: Transaction[] = [
  {
    id: 'TXN-001',
    orden: 'ORD-2025-001',
    mesa: 'Mesa 5',
    metodoPago: 'Efectivo',
    subtotal: 137.00,
    propina: 15.00,
    total: 152.00,
    origen: 'Local'
  },
  {
    id: 'TXN-002',
    orden: 'ORD-2025-002',
    mesa: null,
    cliente: 'Jahir',
    metodoPago: 'Tarjeta',
    subtotal: 104.00,
    propina: 12.00,
    total: 116.00,
    origen: 'Para llevar'
  },
  {
    id: 'TXN-003',
    orden: 'ORD-2025-003',
    mesa: 'Mesa 3',
    metodoPago: 'Efectivo',
    subtotal: 132.05,
    propina: 0.00,
    total: 132.05,
    origen: 'Local'
  },
  {
    id: 'TXN-004',
    orden: 'ORD-2025-004',
    mesa: 'Mesa 8',
    metodoPago: 'Tarjeta',
    subtotal: 89.50,
    propina: 10.00,
    total: 99.50,
    origen: 'Local'
  },
  {
    id: 'TXN-005',
    orden: 'ORD-2025-005',
    mesa: null,
    cliente: 'María González',
    metodoPago: 'Efectivo',
    subtotal: 76.00,
    propina: 8.00,
    total: 84.00,
    origen: 'Para llevar'
  }
];

export function ClosureDetailPanel({
  closure,
  isOpen,
  onClose,
  onMarkVerified,
  onRequestClarification,
  onPrintDetail,
  isMobile = false,
  userRole
}: ClosureDetailPanelProps) {
  const [isVerifying, setIsVerifying] = useState(false);

  if (!closure) return null;

  const handleMarkVerified = async () => {
    if (userRole !== 'admin') return;
    
    setIsVerifying(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate API call
      onMarkVerified(closure.id);
      toast("Cierre marcado como verificado");
      onClose();
    } catch (error) {
      toast("Error al verificar cierre");
    } finally {
      setIsVerifying(false);
    }
  };

  const handleRequestClarification = () => {
    if (userRole !== 'admin') return;
    
    onRequestClarification(closure.id);
    toast("Solicitud de aclaración enviada al cajero");
    onClose();
  };

  const handlePrintDetail = () => {
    onPrintDetail(closure.id);
    toast("Imprimiendo detalle del cierre");
  };

  const getStatusBadge = (estado: string) => {
    if (estado === 'Verificado') {
      return (
        <Badge className="bg-green-100 text-green-800 border-green-300">
          <CheckCircle className="h-3 w-3 mr-1" />
          Verificado
        </Badge>
      );
    }
    return (
      <Badge className="bg-amber-100 text-amber-800 border-amber-300">
        <AlertCircle className="h-3 w-3 mr-1" />
        Pendiente verificación
      </Badge>
    );
  };

  const summaryCards = [
    {
      title: 'Total Neto',
      value: closure.totalNeto,
      icon: DollarSign,
      bgColor: 'bg-gray-50',
      textColor: 'text-gray-800'
    },
    {
      title: 'Efectivo Contado',
      value: closure.efectivo,
      icon: DollarSign,
      bgColor: 'bg-green-50',
      textColor: 'text-green-800'
    },
    {
      title: 'Tarjeta Total',
      value: closure.tarjeta,
      icon: CreditCard,
      bgColor: 'bg-blue-50',
      textColor: 'text-blue-800'
    },
    {
      title: 'Propinas Tarjeta',
      value: closure.propinasTarjeta,
      icon: Star,
      bgColor: 'bg-purple-50',
      textColor: 'text-purple-800'
    },
    {
      title: 'Propinas Efectivo',
      value: closure.propinasEfectivo,
      icon: Star,
      bgColor: 'bg-amber-50',
      textColor: 'text-amber-800'
    },
    {
      title: 'Otros Ingresos',
      value: 50, // Mock value
      icon: DollarSign,
      bgColor: 'bg-indigo-50',
      textColor: 'text-indigo-800'
    }
  ];

  const Content = () => (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-medium text-amber-900">
            Cierre de caja — {closure.fecha}
          </h3>
          <p className="text-sm text-amber-700">
            Usuario: {closure.usuario} • Tipo: {closure.periodo}
          </p>
        </div>
        {getStatusBadge(closure.estado)}
      </div>

      {/* Resumen cards */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        {summaryCards.map((card, index) => {
          const IconComponent = card.icon;
          return (
            <Card key={index} className={`${card.bgColor} border`}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs text-gray-600 mb-1">{card.title}</p>
                    <p className={`text-lg font-medium ${card.textColor}`}>
                      ${card.value.toFixed(2)}
                    </p>
                  </div>
                  <IconComponent className={`h-5 w-5 ${card.textColor} opacity-60`} />
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <Separator />

      {/* Tabla de movimientos */}
      <div>
        <h4 className="font-medium text-amber-900 mb-4">Movimientos Individuales</h4>
        <Card className="border-amber-200">
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Orden</TableHead>
                    <TableHead>Mesa/Cliente</TableHead>
                    <TableHead>Método Pago</TableHead>
                    <TableHead className="text-right">Subtotal</TableHead>
                    <TableHead className="text-right">Propina</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                    <TableHead>Origen</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {mockTransactions.map((transaction) => (
                    <TableRow key={transaction.id}>
                      <TableCell className="font-mono text-sm">
                        {transaction.orden}
                      </TableCell>
                      <TableCell>
                        {transaction.mesa || transaction.cliente}
                      </TableCell>
                      <TableCell>
                        <Badge 
                          variant={transaction.metodoPago === 'Efectivo' ? 'secondary' : 'default'}
                          className={
                            transaction.metodoPago === 'Efectivo' 
                              ? 'bg-green-100 text-green-800 border-green-300'
                              : 'bg-blue-100 text-blue-800 border-blue-300'
                          }
                        >
                          {transaction.metodoPago}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right">
                        ${transaction.subtotal.toFixed(2)}
                      </TableCell>
                      <TableCell className="text-right">
                        {transaction.propina > 0 ? (
                          <span className="text-green-600">
                            +${transaction.propina.toFixed(2)}
                          </span>
                        ) : (
                          <span className="text-gray-400">$0.00</span>
                        )}
                      </TableCell>
                      <TableCell className="text-right font-medium">
                        ${transaction.total.toFixed(2)}
                      </TableCell>
                      <TableCell>
                        <Badge 
                          variant="outline"
                          className={
                            transaction.origen === 'Local'
                              ? 'border-amber-300 text-amber-700'
                              : 'border-indigo-300 text-indigo-700'
                          }
                        >
                          {transaction.origen}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Notas del cajero */}
      <Card className="border-amber-200 bg-amber-50">
        <CardContent className="p-4">
          <h4 className="font-medium text-amber-900 mb-2">Notas del Cajero</h4>
          <p className="text-sm text-amber-800">
            Conteo realizado a las 22:30. Todo correcto, solo sobraron $30 en monedas. 
            Se registraron 24 transacciones en total.
          </p>
        </CardContent>
      </Card>

      {/* Botones de acción */}
      <div className="flex flex-col sm:flex-row gap-3">
        <Button
          variant="outline"
          onClick={handlePrintDetail}
          className="border-amber-300 text-amber-700 hover:bg-amber-50"
        >
          <Printer className="h-4 w-4 mr-2" />
          Imprimir detalle
        </Button>

        {userRole === 'admin' && closure.estado === 'Pendiente verificación' && (
          <>
            <Button
              variant="outline"
              onClick={handleRequestClarification}
              className="border-orange-300 text-orange-700 hover:bg-orange-50"
            >
              <AlertCircle className="h-4 w-4 mr-2" />
              Solicitar aclaración
            </Button>
            <Button
              onClick={handleMarkVerified}
              disabled={isVerifying}
              className="bg-green-600 hover:bg-green-700 text-white"
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              {isVerifying ? 'Verificando...' : 'Marcar verificado'}
            </Button>
          </>
        )}
      </div>

      {/* Microcopy de verificación */}
      {closure.estado === 'Verificado' && (
        <div className="text-xs text-green-600 bg-green-50 p-2 rounded border border-green-200">
          Cierre verificado por Admin — 2025-09-22 23:15:30
        </div>
      )}
    </div>
  );

  if (isMobile) {
    return (
      <Sheet open={isOpen} onOpenChange={onClose}>
        <SheetContent side="bottom" className="h-[90vh] overflow-y-auto">
          <SheetHeader>
            <SheetTitle>Detalle del cierre</SheetTitle>
            <SheetDescription>
              Información detallada del cierre de caja
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
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-2xl lg:max-w-3xl xl:max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Detalle del cierre</DialogTitle>
          <DialogDescription>
            Información detallada del cierre de caja
          </DialogDescription>
        </DialogHeader>
        <Content />
      </DialogContent>
    </Dialog>
  );
}