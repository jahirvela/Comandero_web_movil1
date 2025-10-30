import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Separator } from './ui/separator';
import { Receipt, DollarSign, X } from 'lucide-react';
import { toast } from 'sonner@2.0.3';
import { useNotifications } from './NotificationContext';

interface OrderItem {
  id: string;
  name: string;
  quantity: number;
  price: number;
  extras?: string[];
  customizations?: any;
}

interface CerrarCuentaModalProps {
  isOpen: boolean;
  onClose: () => void;
  tableNumber: number;
  orderSummary: OrderItem[];
  waiterName: string;
  onAccountSent?: (accountData: any) => void;
}

export function CerrarCuentaModal({ 
  isOpen, 
  onClose, 
  tableNumber, 
  orderSummary, 
  waiterName,
  onAccountSent 
}: CerrarCuentaModalProps) {

  const { addNotification } = useNotifications();

  // Calcular totales
  const subtotal = orderSummary.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  const impuestos = 0; // No se especificaron impuestos en el sistema
  const descuentos = 0; // No se especificaron descuentos
  const total = subtotal - descuentos + impuestos;

  const handleSendToCashier = () => {
    const accountId = `ACC-${Date.now().toString().slice(-6)}`;
    const timestamp = new Date().toLocaleTimeString('es-MX', { 
      hour: '2-digit', 
      minute: '2-digit' 
    });

    // Datos de la cuenta para enviar al cajero
    const accountData = {
      id: accountId,
      tableNumber: tableNumber,
      items: orderSummary,
      subtotal: subtotal,
      impuestos: impuestos,
      descuentos: descuentos,
      total: total,
      waiterName: waiterName,
      timestamp: timestamp,
      status: 'por-cobrar'
    };

    // Enviar notificación al cajero
    addNotification({
      type: 'bill_request',
      title: 'Nueva cuenta para cobrar',
      message: `Mesa ${tableNumber} • $${total}`,
      targetRole: 'cajero',
      fromUser: waiterName,
      fromRole: 'mesero',
      tableNumber: tableNumber,
      accountId: accountId,
      total: total,
      priority: 'normal',
      accountData: accountData
    });

    // Llamar callback si existe
    if (onAccountSent) {
      onAccountSent(accountData);
    }

    // Mostrar confirmación
    toast.success(`Cuenta enviada al Cajero — Mesa ${tableNumber}`);

    // Cerrar modal
    onClose();
  };



  const formatExtras = (item: OrderItem) => {
    const extras = [];
    
    if (item.extras && item.extras.length > 0) {
      extras.push(...item.extras);
    }
    
    if (item.customizations) {
      if (item.customizations.salsa) {
        extras.push(`Salsa: ${item.customizations.salsa}`);
      }
      if (item.customizations.tortilla) {
        extras.push(`Tortilla: ${item.customizations.tortilla}`);
      }
      if (item.customizations.spiciness) {
        extras.push(`Picante: ${item.customizations.spiciness}`);
      }
    }
    
    return extras.length > 0 ? extras.join(', ') : '-';
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-xl lg:max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle className="text-xl font-medium text-amber-900 flex items-center gap-2">
            <Receipt className="h-5 w-5" />
            Cerrar cuenta — Mesa {tableNumber}
          </DialogTitle>
          <DialogDescription className="text-amber-700">
            Resumen de consumo
          </DialogDescription>
        </DialogHeader>

        {/* Lista de items - con scroll si excede altura */}
        <div className="flex-1 overflow-y-auto border border-amber-200 rounded-lg">
          <div className="bg-amber-50">
            {/* Header de tabla */}
            <div className="grid grid-cols-12 gap-2 p-3 border-b border-amber-200 bg-amber-100">
              <div className="col-span-2 text-sm font-medium text-amber-900">Cantidad</div>
              <div className="col-span-4 text-sm font-medium text-amber-900">Nombre del producto</div>
              <div className="col-span-3 text-sm font-medium text-amber-900">Extras / Salsas</div>
              <div className="col-span-2 text-sm font-medium text-amber-900">Precio Unit.</div>
              <div className="col-span-1 text-sm font-medium text-amber-900">Subtotal</div>
            </div>
            
            {/* Items */}
            {orderSummary.map((item, index) => (
              <div key={item.id || index} className="grid grid-cols-12 gap-2 p-3 border-b border-amber-200 last:border-b-0">
                <div className="col-span-2 text-sm text-amber-900">
                  <Badge variant="outline" className="border-amber-300 text-amber-800">
                    {item.quantity}
                  </Badge>
                </div>
                <div className="col-span-4 text-sm text-amber-900 font-medium">
                  {item.name}
                </div>
                <div className="col-span-3 text-xs text-amber-700">
                  {formatExtras(item)}
                </div>
                <div className="col-span-2 text-sm text-orange-600 font-medium">
                  ${item.price}
                </div>
                <div className="col-span-1 text-sm text-orange-600 font-medium">
                  ${item.price * item.quantity}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Resumen de totales */}
        <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 space-y-2">
          <div className="flex justify-between text-sm text-amber-900">
            <span>Subtotal:</span>
            <span>${subtotal}</span>
          </div>
          
          {impuestos > 0 && (
            <div className="flex justify-between text-sm text-amber-900">
              <span>Impuestos:</span>
              <span>${impuestos}</span>
            </div>
          )}
          
          {descuentos > 0 && (
            <div className="flex justify-between text-sm text-green-700">
              <span>Descuentos:</span>
              <span>-${descuentos}</span>
            </div>
          )}
          
          <Separator className="bg-amber-300" />
          
          <div className="flex justify-between text-lg font-medium text-amber-900">
            <span>Total:</span>
            <span className="text-orange-600">${total}</span>
          </div>
        </div>

        {/* Microcopy */}
        <div className="text-xs text-amber-600 text-center px-2">
          Al enviar la cuenta, llegará al Cajero para su cobro e impresión de ticket.
        </div>

        {/* Footer con controles */}
        <div className="flex gap-3 pt-4">
          <Button
            variant="outline"
            onClick={onClose}
            className="flex-1 border-amber-300 text-amber-700 hover:bg-amber-100"
          >
            <X className="h-4 w-4 mr-2" />
            Cancelar
          </Button>
          
          <Button
            onClick={handleSendToCashier}
            className="flex-1 bg-green-600 hover:bg-green-700 text-white"
          >
            <DollarSign className="h-4 w-4 mr-2" />
            Enviar al Cajero
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}