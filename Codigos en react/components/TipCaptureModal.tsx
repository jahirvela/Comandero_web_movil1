import React, { useState } from 'react';
import { Button } from './ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from './ui/dialog';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Checkbox } from './ui/checkbox';
import { Calculator, DollarSign } from 'lucide-react';

interface TipCaptureModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (tipData: TipData) => void;
  orderTotal: number;
  paymentMethod: 'cash' | 'card';
}

interface TipData {
  amount: number;
  percentage?: number;
  isCustom: boolean;
  deliveredInCash?: boolean;
}

const SUGGESTED_PERCENTAGES = [
  { label: '10%', value: 0.10 },
  { label: '15%', value: 0.15 },
  { label: '20%', value: 0.20 }
];

export function TipCaptureModal({ 
  isOpen, 
  onClose, 
  onConfirm, 
  orderTotal, 
  paymentMethod 
}: TipCaptureModalProps) {
  const [selectedPercentage, setSelectedPercentage] = useState<number | null>(null);
  const [customAmount, setCustomAmount] = useState('');
  const [deliveredInCash, setDeliveredInCash] = useState(false);

  const calculateTipAmount = (percentage: number) => {
    return orderTotal * percentage;
  };

  const getCurrentTipAmount = () => {
    if (selectedPercentage !== null) {
      return calculateTipAmount(selectedPercentage);
    }
    return parseFloat(customAmount) || 0;
  };

  const handlePercentageSelect = (percentage: number) => {
    setSelectedPercentage(percentage);
    setCustomAmount('');
  };

  const handleCustomAmountChange = (value: string) => {
    setCustomAmount(value);
    setSelectedPercentage(null);
  };

  const handleConfirm = () => {
    const tipAmount = getCurrentTipAmount();
    
    if (tipAmount < 0) {
      alert('El monto de propina no puede ser negativo');
      return;
    }

    const tipData: TipData = {
      amount: tipAmount,
      percentage: selectedPercentage,
      isCustom: selectedPercentage === null,
      deliveredInCash: paymentMethod === 'card' && deliveredInCash
    };

    onConfirm(tipData);
    handleClose();
  };

  const handleClose = () => {
    setSelectedPercentage(null);
    setCustomAmount('');
    setDeliveredInCash(false);
    onClose();
  };

  const handleSkip = () => {
    const tipData: TipData = {
      amount: 0,
      isCustom: false
    };
    onConfirm(tipData);
    handleClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <DollarSign className="h-5 w-5" />
            ¿Agregar propina?
          </DialogTitle>
          <DialogDescription>
            Selecciona el porcentaje de propina o ingresa un monto personalizado
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4 py-4">
          {/* Monto de la cuenta */}
          <div className="bg-muted p-3 rounded-md">
            <div className="flex justify-between items-center">
              <span className="text-sm">Total de la cuenta:</span>
              <span className="font-medium">${orderTotal.toFixed(2)}</span>
            </div>
          </div>

          {/* Porcentajes sugeridos */}
          <div>
            <Label className="mb-2 block">Porcentajes sugeridos</Label>
            <div className="grid grid-cols-3 gap-2">
              {SUGGESTED_PERCENTAGES.map((suggestion) => (
                <Button
                  key={suggestion.label}
                  variant={selectedPercentage === suggestion.value ? "default" : "outline"}
                  size="sm"
                  onClick={() => handlePercentageSelect(suggestion.value)}
                  className="flex flex-col h-auto py-2"
                >
                  <span className="text-xs">{suggestion.label}</span>
                  <span className="text-xs font-normal">
                    ${calculateTipAmount(suggestion.value).toFixed(2)}
                  </span>
                </Button>
              ))}
            </div>
          </div>

          {/* Monto personalizado */}
          <div>
            <Label htmlFor="custom-tip">Monto personalizado</Label>
            <Input
              id="custom-tip"
              type="number"
              step="0.01"
              min="0"
              placeholder="0.00"
              value={customAmount}
              onChange={(e) => handleCustomAmountChange(e.target.value)}
            />
          </div>

          {/* Opción para pago con tarjeta */}
          {paymentMethod === 'card' && (
            <div className="flex items-center space-x-2 p-3 bg-blue-50 rounded-md">
              <Checkbox
                id="cash-tip"
                checked={deliveredInCash}
                onCheckedChange={setDeliveredInCash}
              />
              <Label htmlFor="cash-tip" className="text-sm">
                Propina entregada en efectivo
              </Label>
            </div>
          )}

          {/* Vista previa del total */}
          {getCurrentTipAmount() > 0 && (
            <div className="bg-green-50 p-3 rounded-md border border-green-200">
              <div className="space-y-1 text-sm">
                <div className="flex justify-between">
                  <span>Subtotal:</span>
                  <span>${orderTotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between">
                  <span>Propina:</span>
                  <span>${getCurrentTipAmount().toFixed(2)}</span>
                </div>
                <div className="flex justify-between font-medium border-t border-green-300 pt-1">
                  <span>Total con propina:</span>
                  <span>${(orderTotal + getCurrentTipAmount()).toFixed(2)}</span>
                </div>
              </div>
            </div>
          )}
        </div>

        <DialogFooter className="flex gap-2">
          <Button variant="outline" onClick={handleSkip}>
            Sin propina
          </Button>
          <Button onClick={handleConfirm}>
            Confirmar
            {getCurrentTipAmount() > 0 && (
              <span className="ml-1">(+${getCurrentTipAmount().toFixed(2)})</span>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}