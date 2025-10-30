import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { Label } from './ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Textarea } from './ui/textarea';
import { Checkbox } from './ui/checkbox';

interface ReportOrderModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: ReportData) => void;
  orderId: string;
  tableNumber?: number;
  isTakeaway?: boolean;
  customerName?: string;
}

interface ReportData {
  type: 'demora' | 'cancelacion' | 'cambio';
  reason: string;
  details?: string;
  notifyKitchen: boolean;
}

export function ReportOrderModal({ 
  isOpen, 
  onClose, 
  onSubmit, 
  orderId, 
  tableNumber, 
  isTakeaway = false, 
  customerName 
}: ReportOrderModalProps) {
  const [type, setType] = useState<'demora' | 'cancelacion' | 'cambio' | ''>('');
  const [reason, setReason] = useState('');
  const [customReason, setCustomReason] = useState('');
  const [details, setDetails] = useState('');
  const [notifyKitchen, setNotifyKitchen] = useState(true);

  const reasonOptions = [
    'Mucho tiempo de espera',
    'Cliente se retiró',
    'Cliente cambió pedido',
    'Falta ingrediente',
    'Error en comanda',
    'Otro'
  ];

  const handleSubmit = () => {
    if (!type || (!reason && customReason === '')) return;

    const reportData: ReportData = {
      type: type as 'demora' | 'cancelacion' | 'cambio',
      reason: reason === 'Otro' ? customReason : reason,
      details: details || undefined,
      notifyKitchen
    };

    onSubmit(reportData);
    handleClose();
  };

  const handleClose = () => {
    setType('');
    setReason('');
    setCustomReason('');
    setDetails('');
    setNotifyKitchen(true);
    onClose();
  };

  const getOrderDescription = () => {
    if (isTakeaway) {
      return `Solo para llevar${customerName ? ` (${customerName})` : ''}`;
    }
    return `Mesa ${tableNumber}`;
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Reportar estado de orden</DialogTitle>
          <DialogDescription>
            Orden {orderId} • {getOrderDescription()}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Tipo */}
          <div className="space-y-2">
            <Label htmlFor="type">Tipo</Label>
            <Select value={type} onValueChange={setType}>
              <SelectTrigger>
                <SelectValue placeholder="Seleccionar tipo" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="demora">Demora</SelectItem>
                <SelectItem value="cancelacion">Cancelación</SelectItem>
                <SelectItem value="cambio">Cambio</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Motivo */}
          <div className="space-y-2">
            <Label htmlFor="reason">Motivo</Label>
            <Select value={reason} onValueChange={setReason}>
              <SelectTrigger>
                <SelectValue placeholder="Seleccionar motivo" />
              </SelectTrigger>
              <SelectContent>
                {reasonOptions.map(option => (
                  <SelectItem key={option} value={option}>
                    {option}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Campo personalizado cuando se selecciona "Otro" */}
          {reason === 'Otro' && (
            <div className="space-y-2">
              <Label htmlFor="customReason">Escribir motivo</Label>
              <Textarea
                id="customReason"
                value={customReason}
                onChange={(e) => setCustomReason(e.target.value)}
                placeholder="Describir el motivo..."
                rows={2}
              />
            </div>
          )}

          {/* Detalles */}
          <div className="space-y-2">
            <Label htmlFor="details">Detalles (opcional)</Label>
            <Textarea
              id="details"
              value={details}
              onChange={(e) => setDetails(e.target.value)}
              placeholder="Agregar detalles adicionales..."
              rows={2}
            />
          </div>

          {/* Notificar al cocinero */}
          <div className="flex items-center space-x-2">
            <Checkbox
              id="notifyKitchen"
              checked={notifyKitchen}
              onCheckedChange={setNotifyKitchen}
            />
            <Label htmlFor="notifyKitchen">Notificar al cocinero</Label>
          </div>

          <div className="text-xs text-muted-foreground">
            La notificación llegará a Cocina y aparecerá en KDS con prioridad. Esta acción quedará registrada.
          </div>

          {/* Botones */}
          <div className="flex gap-2 pt-4">
            <Button variant="outline" onClick={handleClose} className="flex-1">
              Cancelar
            </Button>
            <Button 
              onClick={handleSubmit} 
              className="flex-1"
              disabled={!type || (!reason && customReason === '')}
            >
              Enviar notificación
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}