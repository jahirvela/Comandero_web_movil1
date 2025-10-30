import React, { useState } from 'react';
import { Button } from './ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from './ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Textarea } from './ui/textarea';
import { Checkbox } from './ui/checkbox';
import { Label } from './ui/label';
import { toast } from 'sonner@2.0.3';

interface CancelOrderModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (reason: string, customReason?: string, notifyWaiter?: boolean) => void;
  orderNumber: string;
}

const CANCEL_REASONS = [
  'Cliente se cansó de esperar',
  'Falta de insumos',
  'Error de pedido',
  'Duplicado',
  'Otro'
];

export function CancelOrderModal({ isOpen, onClose, onConfirm, orderNumber }: CancelOrderModalProps) {
  const [selectedReason, setSelectedReason] = useState('');
  const [customReason, setCustomReason] = useState('');
  const [notifyWaiter, setNotifyWaiter] = useState(false);

  const handleConfirm = () => {
    if (!selectedReason) {
      toast.error('Debe seleccionar un motivo de cancelación');
      return;
    }

    if (selectedReason === 'Otro' && !customReason.trim()) {
      toast.error('Debe describir la razón de cancelación');
      return;
    }

    const reason = selectedReason === 'Otro' ? customReason : selectedReason;
    onConfirm(reason, selectedReason === 'Otro' ? customReason : undefined, notifyWaiter);
    
    // Reset form
    setSelectedReason('');
    setCustomReason('');
    setNotifyWaiter(false);
    
    toast.success(`Orden cancelada — motivo: ${reason}`);
  };

  const handleClose = () => {
    setSelectedReason('');
    setCustomReason('');
    setNotifyWaiter(false);
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Justificar cancelación</DialogTitle>
          <DialogDescription>
            Selecciona el motivo de la cancelación del pedido #{orderNumber}
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4 py-4">
          <div>
            <Label htmlFor="reason">Motivo</Label>
            <Select value={selectedReason} onValueChange={setSelectedReason}>
              <SelectTrigger>
                <SelectValue placeholder="Seleccione un motivo" />
              </SelectTrigger>
              <SelectContent>
                {CANCEL_REASONS.map((reason) => (
                  <SelectItem key={reason} value={reason}>
                    {reason}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {selectedReason === 'Otro' && (
            <div>
              <Label htmlFor="custom-reason">Descripción</Label>
              <Textarea
                id="custom-reason"
                placeholder="Describa la razón"
                value={customReason}
                onChange={(e) => setCustomReason(e.target.value)}
                className="min-h-[80px]"
              />
            </div>
          )}

          <div className="flex items-center space-x-2">
            <Checkbox
              id="notify-waiter"
              checked={notifyWaiter}
              onCheckedChange={setNotifyWaiter}
            />
            <Label htmlFor="notify-waiter">Notificar al mesero</Label>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={handleClose}>
            Cancelar
          </Button>
          <Button 
            onClick={handleConfirm} 
            variant="destructive"
            disabled={!selectedReason || (selectedReason === 'Otro' && !customReason.trim())}
          >
            Confirmar cancelación
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}