import React from 'react';
import { Button } from './ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from './ui/dialog';
import { Badge } from './ui/badge';
import { CheckCircle2, Printer, X } from 'lucide-react';
import { PaymentRegistrationData } from './CardComprobantRegistrationModal';

interface CardPaymentSuccessModalProps {
  isOpen: boolean;
  onClose: () => void;
  onPrintReceipt?: () => void;
  registrationData: PaymentRegistrationData;
  orderNumber: string;
}

export function CardPaymentSuccessModal({ 
  isOpen, 
  onClose, 
  onPrintReceipt,
  registrationData,
  orderNumber 
}: CardPaymentSuccessModalProps) {

  const handlePrintReceipt = () => {
    if (onPrintReceipt) {
      onPrintReceipt();
    }
    // Simular impresión
    alert(`Imprimiendo comprobante para ${orderNumber}...`);
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md max-h-[90vh] overflow-y-auto p-0">
        {/* Header */}
        <DialogHeader className="flex flex-row items-center justify-between p-3 sm:p-4 border-b bg-green-600 text-white">
          <div className="flex items-center gap-3">
            <CheckCircle2 className="h-6 w-6" />
            <DialogTitle className="text-lg">Cobrado con tarjeta</DialogTitle>
          </div>
          
          <DialogDescription className="sr-only">
            Confirmación de pago procesado exitosamente
          </DialogDescription>
          
          <Button
            variant="ghost"
            size="sm"
            onClick={onClose}
            className="text-white hover:bg-white/10 p-2"
          >
            <X className="h-4 w-4" />
          </Button>
        </DialogHeader>

        <div className="p-4 sm:p-5 space-y-3">
          {/* Icono de éxito central */}
          <div className="text-center">
            <CheckCircle2 className="h-12 w-12 sm:h-16 sm:w-16 text-green-600 mx-auto mb-2 sm:mb-3" />
            <h3 className="text-lg font-medium text-green-800 mb-1">
              ¡Pago procesado exitosamente!
            </h3>
            <p className="text-sm text-green-600">
              El pago con tarjeta ha sido registrado correctamente
            </p>
          </div>

          {/* Resumen del pago */}
          <div className="p-3 sm:p-4 bg-green-50 rounded-lg border border-green-200 space-y-2 sm:space-y-3">
            <div className="flex items-center gap-2 mb-3">
              <Badge variant={registrationData.method === 'debito' ? 'default' : 'secondary'}>
                Tarjeta de {registrationData.method}
              </Badge>
              <Badge variant="outline">
                {registrationData.terminal}
              </Badge>
            </div>

            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-green-700">Método:</span>
                <span className="font-medium">Tarjeta de {registrationData.method}</span>
              </div>
              
              <div className="flex justify-between">
                <span className="text-green-700">Terminal:</span>
                <span className="font-medium">{registrationData.terminal}</span>
              </div>
              
              <div className="flex justify-between">
                <span className="text-green-700">ID de transacción:</span>
                <span className="font-medium font-mono">{registrationData.transactionId}</span>
              </div>
              
              {registrationData.last4Digits && (
                <div className="flex justify-between">
                  <span className="text-green-700">Últimos 4 dígitos:</span>
                  <span className="font-medium font-mono">****{registrationData.last4Digits}</span>
                </div>
              )}
              
              <div className="border-t border-green-300 pt-2 mt-2">
                <div className="flex justify-between">
                  <span className="text-green-700">Total:</span>
                  <span className="font-medium text-lg">${registrationData.totalAmount.toFixed(2)}</span>
                </div>
                
                {registrationData.tipAmount > 0 && (
                  <div className="flex justify-between">
                    <span className="text-green-700">Propina incluida:</span>
                    <span className="font-medium">${registrationData.tipAmount.toFixed(2)}</span>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Información adicional */}
          <div className="text-center text-sm text-gray-600">
            <p>Orden: {orderNumber}</p>
            <p>Fecha: {registrationData.datetime.toLocaleString('es-MX')}</p>
          </div>
        </div>

        <DialogFooter className="p-3 sm:p-4 border-t">
          <div className="flex gap-2 sm:gap-3 w-full">
            <Button 
              variant="outline" 
              onClick={handlePrintReceipt}
              className="flex-1 border-blue-300 text-blue-700"
            >
              <Printer className="h-4 w-4 mr-2" />
              Imprimir comprobante
            </Button>
            <Button 
              onClick={onClose}
              className="flex-1 bg-green-600 hover:bg-green-700"
            >
              Cerrar
            </Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}