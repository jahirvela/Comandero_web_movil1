import React, { useState } from 'react';
import { Button } from './ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from './ui/dialog';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { RadioGroup, RadioGroupItem } from './ui/radio-group';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from './ui/alert-dialog';
import { Calculator, DollarSign, Banknote } from 'lucide-react';
import { toast } from 'sonner@2.0.3';

interface CashCountModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (countData: CashCountData) => void;
  expectedTotal: number;
}

interface CashCountData {
  method: 'manual' | 'detailed';
  totalCounted: number;
  billBreakdown?: {
    [denomination: string]: number;
  };
  difference: number;
}

const BILL_DENOMINATIONS = [
  { value: 1000, label: '$1000' },
  { value: 500, label: '$500' },
  { value: 200, label: '$200' },
  { value: 100, label: '$100' },
  { value: 50, label: '$50' },
  { value: 20, label: '$20' },
  { value: 10, label: '$10' },
  { value: 5, label: '$5' },
  { value: 2, label: '$2' },
  { value: 1, label: '$1' }
];

export function CashCountModal({ isOpen, onClose, onSubmit, expectedTotal }: CashCountModalProps) {
  const [countMethod, setCountMethod] = useState<'manual' | 'detailed'>('detailed');
  const [manualTotal, setManualTotal] = useState('');
  const [billCounts, setBillCounts] = useState<{[key: number]: number}>({});
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);

  const calculateDetailedTotal = () => {
    return Object.entries(billCounts).reduce((total, [denomination, count]) => {
      return total + (parseInt(denomination) * count);
    }, 0);
  };

  const getCurrentTotal = () => {
    if (countMethod === 'manual') {
      return parseFloat(manualTotal) || 0;
    }
    return calculateDetailedTotal();
  };

  const getDifference = () => {
    return getCurrentTotal() - expectedTotal;
  };

  const handleBillCountChange = (denomination: number, count: string) => {
    const numCount = parseInt(count) || 0;
    setBillCounts(prev => ({
      ...prev,
      [denomination]: numCount
    }));
  };

  const handleSubmit = () => {
    const total = getCurrentTotal();
    
    if (total <= 0) {
      toast.error('Debe ingresar un monto válido');
      return;
    }

    setShowConfirmDialog(true);
  };

  const handleConfirmSubmit = () => {
    const countData: CashCountData = {
      method: countMethod,
      totalCounted: getCurrentTotal(),
      billBreakdown: countMethod === 'detailed' ? billCounts : undefined,
      difference: getDifference()
    };

    onSubmit(countData);
    handleClose();
    setShowConfirmDialog(false);
    
    toast.success('Conteo enviado al Administrador');
  };

  const handleClose = () => {
    setCountMethod('detailed');
    setManualTotal('');
    setBillCounts({});
    setShowConfirmDialog(false);
    onClose();
  };

  const difference = getDifference();
  const hasDifference = Math.abs(difference) > 0.01;

  return (
    <>
      <Dialog open={isOpen} onOpenChange={handleClose}>
        <DialogContent className="sm:max-w-md lg:max-w-lg max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Calculator className="h-5 w-5" />
              Conteo de efectivo - Cierre de caja
            </DialogTitle>
            <DialogDescription>
              Ingresa el conteo de efectivo físico para el cierre de caja
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            {/* Total esperado */}
            <div className="bg-muted p-3 rounded-md">
              <div className="flex justify-between items-center">
                <span className="text-sm">Total esperado:</span>
                <span className="font-medium">${expectedTotal.toFixed(2)}</span>
              </div>
            </div>

            {/* Método de conteo */}
            <div>
              <Label className="mb-3 block">Método de conteo</Label>
              <RadioGroup value={countMethod} onValueChange={(value: 'manual' | 'detailed') => setCountMethod(value)}>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="detailed" id="detailed" />
                  <Label htmlFor="detailed">Contar billetes</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="manual" id="manual" />
                  <Label htmlFor="manual">Ingresar total manualmente</Label>
                </div>
              </RadioGroup>
            </div>

            {/* Conteo manual */}
            {countMethod === 'manual' && (
              <div>
                <Label htmlFor="manual-total">Total contado ($)</Label>
                <Input
                  id="manual-total"
                  type="number"
                  step="0.01"
                  placeholder="0.00"
                  value={manualTotal}
                  onChange={(e) => setManualTotal(e.target.value)}
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Si prefiere, ingrese el total contado y envíe al Admin.
                </p>
              </div>
            )}

            {/* Conteo detallado */}
            {countMethod === 'detailed' && (
              <div>
                <Label className="mb-3 block">Conteo por denominación</Label>
                <div className="space-y-2 max-h-60 overflow-y-auto">
                  {BILL_DENOMINATIONS.map((bill) => (
                    <div key={bill.value} className="flex items-center gap-3 p-2 bg-muted/50 rounded">
                      <div className="w-16 text-sm font-medium">{bill.label}</div>
                      <div className="flex items-center gap-2 flex-1">
                        <Input
                          type="number"
                          min="0"
                          placeholder="0"
                          value={billCounts[bill.value] || ''}
                          onChange={(e) => handleBillCountChange(bill.value, e.target.value)}
                          className="w-20"
                        />
                        <span className="text-xs text-muted-foreground">×</span>
                        <div className="text-sm">
                          ${((billCounts[bill.value] || 0) * bill.value).toFixed(2)}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Resumen */}
            <div className="bg-blue-50 p-3 rounded-md border border-blue-200">
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span>Total esperado:</span>
                  <span>${expectedTotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between">
                  <span>Total contado:</span>
                  <span className="font-medium">${getCurrentTotal().toFixed(2)}</span>
                </div>
                <div className={`flex justify-between font-medium border-t border-blue-300 pt-2 ${
                  difference > 0 ? 'text-green-600' : difference < 0 ? 'text-red-600' : 'text-blue-600'
                }`}>
                  <span>Diferencia:</span>
                  <span>
                    {difference > 0 ? '+' : ''}${difference.toFixed(2)}
                    {hasDifference && (
                      <span className="ml-1 text-xs">
                        ({difference > 0 ? 'Sobrante' : 'Faltante'})
                      </span>
                    )}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={handleClose}>
              Cancelar
            </Button>
            <Button 
              onClick={handleSubmit}
              disabled={getCurrentTotal() <= 0}
            >
              <Banknote className="h-4 w-4 mr-2" />
              Enviar conteo
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo de confirmación */}
      <AlertDialog open={showConfirmDialog} onOpenChange={setShowConfirmDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar conteo de efectivo</AlertDialogTitle>
            <AlertDialogDescription className="space-y-2">
              <div>¿Está seguro de enviar el siguiente conteo?</div>
              <div className="bg-muted p-2 rounded text-sm">
                <div>Total contado: <strong>${getCurrentTotal().toFixed(2)}</strong></div>
                <div>Diferencia: <strong className={difference > 0 ? 'text-green-600' : difference < 0 ? 'text-red-600' : ''}>
                  {difference > 0 ? '+' : ''}${difference.toFixed(2)}
                </strong></div>
              </div>
              <div className="text-xs text-muted-foreground">
                Esta información será enviada al Administrador para su revisión.
              </div>
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={handleConfirmSubmit}>
              Confirmar y enviar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}