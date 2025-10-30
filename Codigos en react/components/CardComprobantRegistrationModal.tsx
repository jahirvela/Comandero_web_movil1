import React, { useState } from 'react';
import { Button } from './ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from './ui/dialog';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { Checkbox } from './ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Badge } from './ui/badge';
import { X, FileText, CheckCircle2, AlertCircle } from 'lucide-react';
import { toast } from 'sonner@2.0.3';
import { CardPaymentData } from './NewCardPaymentModal';

interface CardComprobantRegistrationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirmPayment: (registrationData: PaymentRegistrationData) => void;
  paymentData: CardPaymentData;
  orderNumber: string;
}

export interface PaymentRegistrationData {
  method: 'debito' | 'credito';
  terminal: string;
  transactionId: string;
  authCode?: string;
  last4Digits?: string;
  totalAmount: number;
  tipAmount: number;
  voucherPrinted: boolean;
  notes?: string;
  datetime: Date;
}

export function CardComprobantRegistrationModal({ 
  isOpen, 
  onClose, 
  onConfirmPayment, 
  paymentData,
  orderNumber 
}: CardComprobantRegistrationModalProps) {
  const [transactionId, setTransactionId] = useState('');
  const [authCode, setAuthCode] = useState('');
  const [last4Digits, setLast4Digits] = useState('');
  const [voucherPrinted, setVoucherPrinted] = useState(false);
  const [notes, setNotes] = useState('');
  const [datetime, setDatetime] = useState(new Date().toISOString().slice(0, 16));

  const handleConfirm = () => {
    // Validar campos requeridos
    if (!transactionId.trim()) {
      toast.error('El ID de transacción es requerido');
      return;
    }

    // Validar últimos 4 dígitos si se proporcionan
    if (last4Digits && (last4Digits.length !== 4 || !/^\d{4}$/.test(last4Digits))) {
      toast.error('Los últimos 4 dígitos deben ser exactamente 4 números');
      return;
    }

    const registrationData: PaymentRegistrationData = {
      method: paymentData.method,
      terminal: paymentData.terminal,
      transactionId: transactionId.trim(),
      authCode: authCode.trim() || undefined,
      last4Digits: last4Digits || undefined,
      totalAmount: paymentData.total,
      tipAmount: paymentData.tip,
      voucherPrinted,
      notes: notes.trim() || undefined,
      datetime: new Date(datetime)
    };

    onConfirmPayment(registrationData);
    handleClose();
    toast.success('Pago con tarjeta confirmado y registrado');
  };

  const handleClose = () => {
    setTransactionId('');
    setAuthCode('');
    setLast4Digits('');
    setVoucherPrinted(false);
    setNotes('');
    setDatetime(new Date().toISOString().slice(0, 16));
    onClose();
  };

  // Warning si el voucher no está marcado como impreso
  const showVoucherWarning = !voucherPrinted;

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md max-h-[90vh] overflow-y-auto p-0">
        {/* Header */}
        <DialogHeader className="flex flex-row items-center justify-between p-3 sm:p-4 border-b bg-blue-600 text-white">
          <div className="flex items-center gap-3">
            <FileText className="h-5 w-5" />
            <DialogTitle className="text-lg">Registrar comprobante</DialogTitle>
          </div>
          
          <DialogDescription className="sr-only">
            Registrar manualmente los datos del comprobante de tarjeta
          </DialogDescription>
          
          <Button
            variant="ghost"
            size="sm"
            onClick={handleClose}
            className="text-white hover:bg-white/10 p-2"
          >
            <X className="h-4 w-4" />
          </Button>
        </DialogHeader>

        <div className="p-4 sm:p-5 space-y-3">
          {/* Información del pago */}
          <div className="p-2.5 sm:p-3 bg-blue-50 rounded-lg border border-blue-200">
            <div className="flex justify-between items-center mb-2">
              <Badge variant={paymentData.method === 'debito' ? 'default' : 'secondary'}>
                Tarjeta de {paymentData.method}
              </Badge>
              <span className="text-sm text-blue-600">{paymentData.terminal}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-blue-700">Total cobrado:</span>
              <span className="font-medium text-blue-900">${paymentData.total.toFixed(2)}</span>
            </div>
            {paymentData.tip > 0 && (
              <div className="flex justify-between items-center">
                <span className="text-sm text-blue-700">Propina incluida:</span>
                <span className="text-sm text-blue-900">${paymentData.tip.toFixed(2)}</span>
              </div>
            )}
          </div>

          {/* Campos del formulario */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="method">Método</Label>
              <Input
                id="method"
                value={`Tarjeta de ${paymentData.method}`}
                disabled
                className="bg-gray-50"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="terminal">Terminal</Label>
              <Input
                id="terminal"
                value={paymentData.terminal}
                disabled
                className="bg-gray-50"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="datetime">Fecha y hora</Label>
            <Input
              id="datetime"
              type="datetime-local"
              value={datetime}
              onChange={(e) => setDatetime(e.target.value)}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="transactionId" className="flex items-center gap-1">
              ID de transacción (voucher) 
              <span className="text-red-500">*</span>
            </Label>
            <Input
              id="transactionId"
              value={transactionId}
              onChange={(e) => setTransactionId(e.target.value)}
              placeholder="Ej: 123456789012"
              className={!transactionId ? 'border-red-300' : ''}
            />
            {!transactionId && (
              <p className="text-xs text-red-600">Campo requerido</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="authCode">Código de autorización (opcional)</Label>
            <Input
              id="authCode"
              value={authCode}
              onChange={(e) => setAuthCode(e.target.value)}
              placeholder="Ej: 123456"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="last4Digits">Últimos 4 dígitos (opcional)</Label>
            <Input
              id="last4Digits"
              value={last4Digits}
              onChange={(e) => setLast4Digits(e.target.value)}
              placeholder="1234"
              maxLength={4}
              pattern="[0-9]{4}"
            />
          </div>

          {/* Checkbox voucher impreso */}
          <div className="flex items-center space-x-2 p-2.5 sm:p-3 border rounded-lg">
            <Checkbox
              id="voucherPrinted"
              checked={voucherPrinted}
              onCheckedChange={setVoucherPrinted}
            />
            <Label htmlFor="voucherPrinted" className="flex-1">
              Ticket impreso (voucher entregado al cliente)
            </Label>
            {voucherPrinted ? (
              <CheckCircle2 className="h-4 w-4 text-green-600" />
            ) : (
              <AlertCircle className="h-4 w-4 text-amber-600" />
            )}
          </div>

          {/* Warning si no está marcado como impreso */}
          {showVoucherWarning && (
            <div className="p-2.5 sm:p-3 bg-amber-50 border border-amber-200 rounded-md">
              <div className="flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-amber-600" />
                <p className="text-sm text-amber-800">
                  Se recomienda imprimir el voucher para el cliente
                </p>
              </div>
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="notes">Notas / Comentarios</Label>
            <Textarea
              id="notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Ej: Cliente aprobó en terminal; voucher TX..."
              rows={3}
            />
          </div>
        </div>

        <DialogFooter className="p-3 sm:p-4 border-t">
          <div className="flex gap-2 sm:gap-3 w-full">
            <Button variant="outline" onClick={handleClose} className="flex-1">
              Cancelar
            </Button>
            <Button 
              onClick={handleConfirm}
              disabled={!transactionId.trim()}
              className="flex-1 bg-green-600 hover:bg-green-700"
            >
              <CheckCircle2 className="h-4 w-4 mr-2" />
              Confirmar pago
            </Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}