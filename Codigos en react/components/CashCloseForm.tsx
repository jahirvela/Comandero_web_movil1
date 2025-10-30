import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { Save } from 'lucide-react';

interface CashCloseData {
  cashTotal: number;
  cardTotal: number;
  otherIncome: number;
  notes?: string;
}

interface CashCloseFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: CashCloseData) => void;
}

export function CashCloseForm({ isOpen, onClose, onSubmit }: CashCloseFormProps) {
  const [cashTotal, setCashTotal] = useState('');
  const [cardTotal, setCardTotal] = useState('');
  const [otherIncome, setOtherIncome] = useState('');
  const [notes, setNotes] = useState('');

  const handleSubmit = () => {
    const data: CashCloseData = {
      cashTotal: parseFloat(cashTotal) || 0,
      cardTotal: parseFloat(cardTotal) || 0,
      otherIncome: parseFloat(otherIncome) || 0,
      notes: notes.trim() || undefined
    };

    onSubmit(data);
  };

  const isValid = cashTotal && !isNaN(parseFloat(cashTotal));

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-blue-900">Cierre de Caja</DialogTitle>
          <DialogDescription>
            Ingresa los totales del día para enviar el cierre al administrador
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="cashTotal">Efectivo contado hoy *</Label>
          <Input
            id="cashTotal"
            type="number"
            step="0.01"
            min="0"
            value={cashTotal}
            onChange={(e) => setCashTotal(e.target.value)}
            placeholder="ej. 2000"
            className="border-blue-200 focus:border-blue-500"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="cardTotal">Total tarjeta</Label>
          <Input
            id="cardTotal"
            type="number"
            step="0.01"
            min="0"
            value={cardTotal}
            onChange={(e) => setCardTotal(e.target.value)}
            placeholder="ej. 1500"
            className="border-blue-200 focus:border-blue-500"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="otherIncome">Otros ingresos</Label>
          <Input
            id="otherIncome"
            type="number"
            step="0.01"
            min="0"
            value={otherIncome}
            onChange={(e) => setOtherIncome(e.target.value)}
            placeholder="Propinas en efectivo registradas, etc."
            className="border-blue-200 focus:border-blue-500"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="notes">Nota (opcional)</Label>
          <Textarea
            id="notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Comentarios adicionales sobre el cierre..."
            className="border-blue-200 focus:border-blue-500"
            rows={3}
          />
        </div>

        <div className="text-xs text-blue-600 bg-blue-50 p-3 rounded border border-blue-200">
          Al enviar, el resumen llegará al Administrador y quedará registrado en el cierre del día.
        </div>

        <div className="flex gap-2">
          <Button variant="outline" onClick={onClose} className="flex-1">
            Cancelar
          </Button>
          <Button 
            onClick={handleSubmit} 
            className="flex-1 bg-blue-600 hover:bg-blue-700"
            disabled={!isValid}
          >
            <Save className="h-4 w-4 mr-2" />
            Enviar cierre
          </Button>
        </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}