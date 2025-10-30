import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { Checkbox } from './ui/checkbox';
import { Separator } from './ui/separator';
import { DollarSign, Calculator, AlertCircle } from 'lucide-react';
import { toast } from 'sonner@2.0.3';

interface CashPaymentWithTipsModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (paymentData: any) => void;
  totalAmount: number;
  tableNumber?: number;
  billId: string;
}

export function CashPaymentWithTipsModal({ 
  isOpen, 
  onClose, 
  onConfirm, 
  totalAmount,
  tableNumber,
  billId 
}: CashPaymentWithTipsModalProps) {
  const [cashReceived, setCashReceived] = useState('');
  const [tipAmount, setTipAmount] = useState('');
  const [tipDelivered, setTipDelivered] = useState(false);
  const [notes, setNotes] = useState('');

  const [calculatedCashApplied, setCalculatedCashApplied] = useState(0);
  const [calculatedChange, setCalculatedChange] = useState(0);
  const [hasError, setHasError] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    const received = parseFloat(cashReceived) || 0;
    const tip = parseFloat(tipAmount) || 0;
    
    const cashApplied = received - tip;
    const change = cashApplied - totalAmount;
    
    setCalculatedCashApplied(cashApplied);
    setCalculatedChange(change);
    
    if (cashApplied < totalAmount) {
      setHasError(true);
      setErrorMessage('Efectivo insuficiente para cubrir el total');
    } else if (change < 0) {
      setHasError(true);
      setErrorMessage('El efectivo aplicado es insuficiente');
    } else {
      setHasError(false);
      setErrorMessage('');
    }
  }, [cashReceived, tipAmount, totalAmount]);

  const handleConfirm = () => {
    if (!cashReceived) {
      toast.error('Ingresa el efectivo recibido');
      return;
    }

    const received = parseFloat(cashReceived);
    if (received <= 0) {
      toast.error('El efectivo recibido debe ser mayor a 0');
      return;
    }

    if (hasError) {
      toast.error(errorMessage);
      return;
    }

    const paymentData = {
      type: 'cash',
      totalAmount,
      cashReceived: received,
      tipAmount: parseFloat(tipAmount) || 0,
      tipDelivered,
      cashApplied: calculatedCashApplied,
      change: calculatedChange,
      notes: notes.trim(),
      tableNumber,
      billId,
      timestamp: new Date().toISOString()
    };

    onConfirm(paymentData);
    handleReset();
  };

  const handleReset = () => {
    setCashReceived('');
    setTipAmount('');
    setTipDelivered(false);
    setNotes('');
  };

  const handleClose = () => {
    handleReset();
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <DollarSign className="h-5 w-5 text-primary" />
            Confirmar cobro en efectivo
          </DialogTitle>
          <DialogDescription>
            Registra el efectivo recibido y las propinas para completar el cobro
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Resumen del pago */}
          <div className="p-3 bg-muted rounded-lg">
            <div className="flex justify-between text-sm">
              <span>Total a pagar:</span>
              <span className="font-semibold text-primary">${totalAmount.toFixed(2)}</span>
            </div>
            {tableNumber && (
              <div className="flex justify-between text-sm mt-1">
                <span>Mesa:</span>
                <span>{tableNumber}</span>
              </div>
            )}
          </div>

          {/* Efectivo recibido */}
          <div className="space-y-2">
            <Label htmlFor="cashReceived">Efectivo recibido *</Label>
            <Input
              id="cashReceived"
              type="number"
              step="0.01"
              min="0"
              value={cashReceived}
              onChange={(e) => setCashReceived(e.target.value)}
              placeholder="0.00"
              className="text-right"
            />
          </div>

          {/* Propina en efectivo */}
          <div className="space-y-2">
            <Label htmlFor="tipAmount">
              Propina en efectivo (registrada por mesero)
            </Label>
            <Input
              id="tipAmount"
              type="number"
              step="0.01"
              min="0"
              value={tipAmount}
              onChange={(e) => setTipAmount(e.target.value)}
              placeholder="0.00"
              className="text-right"
            />
            <p className="text-xs text-muted-foreground">
              Si el cliente dejó propina en efectivo al mesero, regístrala aquí (opcional)
            </p>
          </div>

          {/* Checkbox para propina entregada */}
          {parseFloat(tipAmount) > 0 && (
            <div className="flex items-center space-x-2">
              <Checkbox
                id="tipDelivered"
                checked={tipDelivered}
                onCheckedChange={setTipDelivered}
              />
              <Label htmlFor="tipDelivered" className="text-sm">
                Propina ya entregada al cajero
              </Label>
            </div>
          )}

          {/* Cálculos */}
          <div className="p-3 bg-background border rounded-lg space-y-2">
            <div className="flex justify-between text-sm">
              <span>Efectivo aplicado al pago:</span>
              <span className={calculatedCashApplied >= 0 ? '' : 'text-destructive'}>
                ${calculatedCashApplied.toFixed(2)}
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Cambio a devolver:</span>
              <span className={`font-semibold ${hasError ? 'text-destructive' : 'text-green-600'}`}>
                ${calculatedChange.toFixed(2)}
              </span>
            </div>
            {hasError && (
              <div className="flex items-center gap-2 text-destructive text-xs mt-2">
                <AlertCircle className="h-3 w-3" />
                <span>{errorMessage}</span>
              </div>
            )}
          </div>

          {/* Explicación del cálculo */}
          <div className="text-xs text-muted-foreground p-2 bg-blue-50 rounded border border-blue-200">
            <p className="font-medium text-blue-900 mb-1">Cálculo:</p>
            <p>• Efectivo aplicado = Efectivo recibido - Propina</p>
            <p>• Cambio = Efectivo aplicado - Total a pagar</p>
          </div>

          {/* Notas del pago */}
          <div className="space-y-2">
            <Label htmlFor="notes">Notas del pago (opcional)</Label>
            <Textarea
              id="notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Observaciones adicionales..."
              rows={2}
            />
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
              onClick={handleConfirm}
              className="flex-1"
              disabled={!cashReceived || hasError}
            >
              <Calculator className="h-4 w-4 mr-2" />
              Confirmar cobro
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}