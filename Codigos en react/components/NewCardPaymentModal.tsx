import React, { useState } from 'react';
import { Button } from './ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from './ui/dialog';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Badge } from './ui/badge';
import { X, CreditCard, Wifi, WifiOff, Calculator } from 'lucide-react';
import { toast } from 'sonner@2.0.3';

interface NewCardPaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSendToTerminal: (paymentData: CardPaymentData) => void;
  amount: number;
  orderNumber: string;
  cashier?: string;
}

export interface CardPaymentData {
  method: 'debito' | 'credito';
  terminal: string;
  subtotal: number;
  tip: number;
  total: number;
}

export function NewCardPaymentModal({ 
  isOpen, 
  onClose, 
  onSendToTerminal, 
  amount, 
  orderNumber,
  cashier = "1"
}: NewCardPaymentModalProps) {
  const [paymentMethod, setPaymentMethod] = useState<'debito' | 'credito'>('debito');
  const [selectedTerminal, setSelectedTerminal] = useState('Terminal 1');
  const [tipAmount, setTipAmount] = useState(0);
  const [customTipAmount, setCustomTipAmount] = useState('');
  const [terminalConnected, setTerminalConnected] = useState(true);

  const subtotal = amount;
  const totalAmount = subtotal + tipAmount;

  const handleTipSelection = (percentage: number) => {
    const tip = Math.round((subtotal * percentage / 100) * 100) / 100;
    setTipAmount(tip);
    setCustomTipAmount('');
  };

  const handleCustomTipChange = (value: string) => {
    setCustomTipAmount(value);
    const numValue = parseFloat(value) || 0;
    setTipAmount(Math.max(0, numValue));
  };

  const handleSendToTerminal = () => {
    if (!terminalConnected) {
      toast.error('Terminal desconectado. Verifique la conexión.');
      return;
    }

    const paymentData: CardPaymentData = {
      method: paymentMethod,
      terminal: selectedTerminal,
      subtotal,
      tip: tipAmount,
      total: totalAmount
    };

    onSendToTerminal(paymentData);
    toast.success('Enviado a terminal. Procese el pago en la terminal.');
    handleClose();
  };

  const handleClose = () => {
    setPaymentMethod('debito');
    setSelectedTerminal('Terminal 1');
    setTipAmount(0);
    setCustomTipAmount('');
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-lg max-h-[90vh] overflow-y-auto p-0">
        {/* Header */}
        <DialogHeader className="flex flex-row items-center justify-between p-3 sm:p-4 border-b bg-primary text-primary-foreground">
          <div className="flex items-center gap-3">
            <CreditCard className="h-5 w-5" />
            <DialogTitle className="text-lg">Pagar con tarjeta</DialogTitle>
          </div>
          
          <DialogDescription className="sr-only">
            Configurar pago con tarjeta para procesar en terminal
          </DialogDescription>
          
          <Button
            variant="ghost"
            size="sm"
            onClick={handleClose}
            className="text-primary-foreground hover:bg-primary-foreground/10 p-2"
          >
            <X className="h-4 w-4" />
          </Button>
        </DialogHeader>

        <div className="p-4 sm:p-5 space-y-4">
          {/* Información de caja y total */}
          <div className="flex justify-between items-center p-3 sm:p-4 bg-blue-50 rounded-lg border border-blue-200">
            <div>
              <div className="text-sm text-blue-600">Caja {cashier}</div>
              <div className="text-2xl font-medium text-blue-900">${amount.toFixed(2)} MXN</div>
            </div>
            <div className="text-right">
              <div className="text-sm text-blue-600">Total</div>
              <div className="text-2xl font-medium text-blue-900">${totalAmount.toFixed(2)}</div>
              <div className="flex items-center gap-1 text-sm text-green-600">
                <span className="inline-block w-2 h-2 bg-green-500 rounded-full"></span>
                MXN
              </div>
            </div>
          </div>

          {/* Selector de método */}
          <div className="space-y-2">
            <Label className="text-sm sm:text-base">Método de pago</Label>
            <div className="flex gap-2">
              <Button
                variant={paymentMethod === 'debito' ? 'default' : 'outline'}
                onClick={() => setPaymentMethod('debito')}
                className="flex-1"
              >
                Tarjeta de débito
              </Button>
              <Button
                variant={paymentMethod === 'credito' ? 'default' : 'outline'}
                onClick={() => setPaymentMethod('credito')}
                className="flex-1"
              >
                Tarjeta de crédito
              </Button>
            </div>
          </div>

          {/* Propina */}
          <div className="space-y-2">
            <Label className="text-sm sm:text-base">Propina (opcional)</Label>
            <div className="grid grid-cols-3 gap-2">
              <Button
                variant="outline"
                onClick={() => handleTipSelection(10)}
                className={tipAmount === Math.round((subtotal * 0.10) * 100) / 100 ? 'border-primary bg-primary/5' : ''}
              >
                10%
              </Button>
              <Button
                variant="outline"
                onClick={() => handleTipSelection(15)}
                className={tipAmount === Math.round((subtotal * 0.15) * 100) / 100 ? 'border-primary bg-primary/5' : ''}
              >
                15%
              </Button>
              <Button
                variant="outline"
                onClick={() => handleTipSelection(20)}
                className={tipAmount === Math.round((subtotal * 0.20) * 100) / 100 ? 'border-primary bg-primary/5' : ''}
              >
                20%
              </Button>
            </div>
            
            <div className="space-y-2">
              <Label className="text-sm">Monto personalizado</Label>
              <div className="flex items-center gap-2">
                <span className="text-xl">$</span>
                <Input
                  type="number"
                  value={customTipAmount}
                  onChange={(e) => handleCustomTipChange(e.target.value)}
                  className="text-center"
                  placeholder="0.00"
                  step="0.01"
                  min="0"
                />
              </div>
            </div>
            
            <p className="text-xs text-muted-foreground">
              La propina la confirma el cliente en la terminal; este campo es para registro.
            </p>
          </div>

          {/* Selector de terminal */}
          <div className="space-y-2">
            <Label className="text-sm sm:text-base">Terminal</Label>
            <div className="flex items-center gap-3">
              <Select value={selectedTerminal} onValueChange={setSelectedTerminal}>
                <SelectTrigger className="flex-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Terminal 1">Terminal 1</SelectItem>
                  <SelectItem value="Terminal 2">Terminal 2</SelectItem>
                </SelectContent>
              </Select>
              
              <Badge 
                variant={terminalConnected ? "default" : "destructive"} 
                className="flex items-center gap-1"
              >
                {terminalConnected ? (
                  <>
                    <Wifi className="h-3 w-3" />
                    Conectado
                  </>
                ) : (
                  <>
                    <WifiOff className="h-3 w-3" />
                    Desconectado
                  </>
                )}
              </Badge>
            </div>
          </div>

          {/* Resumen */}
          <div className="space-y-2 p-3 sm:p-4 bg-gray-50 rounded-lg">
            <div className="flex justify-between text-sm">
              <span>Subtotal:</span>
              <span>${subtotal.toFixed(2)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Propina:</span>
              <span>${tipAmount.toFixed(2)}</span>
            </div>
            <div className="flex justify-between font-medium text-base border-t pt-2">
              <span>Total a cobrar:</span>
              <span>${totalAmount.toFixed(2)}</span>
            </div>
          </div>

          {/* Nota informativa */}
          <div className="p-2.5 sm:p-3 bg-amber-50 border border-amber-200 rounded-md">
            <p className="text-xs sm:text-sm text-amber-800">
              <strong>Nota:</strong> Acerca la terminal al cliente. El sistema no procesa la tarjeta: 
              la terminal imprime el voucher. Luego el cajero registra manualmente el comprobante 
              en el formulario de registro.
            </p>
          </div>
        </div>

        <DialogFooter className="p-3 sm:p-4 border-t">
          <div className="flex gap-2 sm:gap-3 w-full">
            <Button variant="outline" onClick={handleClose} className="flex-1">
              Cancelar
            </Button>
            <Button 
              onClick={handleSendToTerminal}
              disabled={!terminalConnected}
              className="flex-1 bg-primary hover:bg-primary/90"
            >
              <Calculator className="h-4 w-4 mr-2" />
              Enviar a terminal
            </Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}