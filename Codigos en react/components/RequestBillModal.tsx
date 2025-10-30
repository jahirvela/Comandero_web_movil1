import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { Textarea } from './ui/textarea';
import { Label } from './ui/label';
import { Separator } from './ui/separator';
import { DollarSign } from 'lucide-react';
import { toast } from 'sonner@2.0.3';
import { useNotifications } from './NotificationContext';

interface RequestBillModalProps {
  isOpen: boolean;
  onClose: () => void;
  tableNumber: number;
  orderSummary: Array<{
    id: string;
    name: string;
    quantity: number;
    price: number;
  }>;
  waiterName: string;
}

export function RequestBillModal({ 
  isOpen, 
  onClose, 
  tableNumber, 
  orderSummary,
  waiterName 
}: RequestBillModalProps) {
  const [notes, setNotes] = useState('');
  const { addNotification } = useNotifications();

  const calculateSubtotal = () => {
    return orderSummary.reduce((total, item) => total + (item.price * item.quantity), 0);
  };

  const calculateTax = (subtotal: number) => {
    return subtotal * 0.16; // 16% IVA
  };

  const calculateTotal = () => {
    const subtotal = calculateSubtotal();
    const tax = calculateTax(subtotal);
    return subtotal + tax;
  };

  const handleRequestBill = () => {
    const billData = {
      id: `BILL-${Date.now()}`,
      tableNumber,
      waiterName,
      items: orderSummary,
      subtotal: calculateSubtotal(),
      tax: calculateTax(calculateSubtotal()),
      total: calculateTotal(),
      notes: notes.trim(),
      requestedAt: new Date().toISOString(),
      status: 'pending',
      priority: 'alta',
      requestedBy: waiterName
    };

    // Notificar al cajero
    addNotification({
      id: `bill-request-${Date.now()}`,
      type: 'bill_request',
      title: 'Solicitud de cuenta',
      message: `Mesa ${tableNumber} — Ver ahora`,
      priority: 'normal',
      fromRole: 'mesero',
      toRole: 'cajero',
      metadata: {
        tableNumber,
        waiterName,
        billData,
        notes
      }
    });

    // Log de auditoría (simulado)
    console.log(`AUDIT_LOG: Cuenta solicitada por Mesero ${waiterName} — Mesa ${tableNumber} — Total: $${calculateTotal().toFixed(2)} — ${new Date().toISOString()}`);

    toast.success(`Cuenta solicitada al cajero para Mesa ${tableNumber}`);
    
    // Limpiar y cerrar
    setNotes('');
    onClose();
  };

  const handleClose = () => {
    setNotes('');
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md lg:max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <DollarSign className="h-5 w-5 text-primary" />
            Solicitar cuenta — Mesa {tableNumber}
          </DialogTitle>
          <DialogDescription>
            Envía la solicitud de cuenta al cajero para procesar el pago
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Resumen de pedidos */}
          <div className="space-y-3">
            <Label>Resumen de pedidos</Label>
            <div className="border rounded-lg p-4 bg-muted/50 max-h-48 overflow-y-auto">
              {orderSummary.length === 0 ? (
                <p className="text-muted-foreground text-sm">No hay productos en el pedido</p>
              ) : (
                <div className="space-y-2">
                  {orderSummary.map((item, index) => (
                    <div key={index} className="flex justify-between items-center">
                      <div className="flex items-center gap-2">
                        <span className="bg-primary/10 text-primary px-2 py-1 rounded text-xs">
                          {item.quantity}x
                        </span>
                        <span className="text-sm">{item.name}</span>
                      </div>
                      <span className="text-sm font-medium">
                        ${(item.price * item.quantity).toFixed(2)}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Totales */}
          <div className="border rounded-lg p-4 bg-background">
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Subtotal:</span>
                <span>${calculateSubtotal().toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span>IVA (16%):</span>
                <span>${calculateTax(calculateSubtotal()).toFixed(2)}</span>
              </div>
              <Separator />
              <div className="flex justify-between font-semibold">
                <span>Total estimado:</span>
                <span className="text-primary">${calculateTotal().toFixed(2)}</span>
              </div>
            </div>
          </div>

          {/* Notas para el cajero */}
          <div className="space-y-2">
            <Label>Notas para cajero (opcional)</Label>
            <Textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Ej: Cliente pide factura, Separar cuenta en dos, etc."
              rows={2}
            />
            <p className="text-xs text-muted-foreground">
              Información adicional que pueda ser útil para el cajero
            </p>
          </div>

          {/* Información del mesero */}
          <div className="p-3 bg-muted rounded-lg">
            <p className="text-sm">
              <span className="font-medium">Solicitado por:</span> {waiterName}
            </p>
          </div>

          {/* Botones */}
          <div className="flex gap-3 pt-4">
            <Button
              variant="outline"
              onClick={handleClose}
              className="flex-1"
            >
              Cancelar
            </Button>
            <Button
              onClick={handleRequestBill}
              className="flex-1"
              disabled={orderSummary.length === 0}
            >
              <DollarSign className="h-4 w-4 mr-2" />
              Solicitar Cuenta
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}