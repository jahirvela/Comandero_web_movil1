import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Textarea } from './ui/textarea';
import { RadioGroup, RadioGroupItem } from './ui/radio-group';
import { Label } from './ui/label';
import { AlertTriangle } from 'lucide-react';
import { toast } from 'sonner@2.0.3';
import { useNotifications } from './NotificationContext';

interface AlertToKitchenModalProps {
  isOpen: boolean;
  onClose: () => void;
  orderId?: string;
  tableNumber?: number;
  waiterName: string;
}

export function AlertToKitchenModal({ 
  isOpen, 
  onClose, 
  orderId, 
  tableNumber, 
  waiterName 
}: AlertToKitchenModalProps) {
  const [alertType, setAlertType] = useState('');
  const [priority, setPriority] = useState('normal');
  const [details, setDetails] = useState('');
  const { addNotification } = useNotifications();

  const alertTypes = [
    { value: 'demora', label: 'Demora' },
    { value: 'cancelacion', label: 'Cancelación' },
    { value: 'cambio', label: 'Cambio en orden' },
    { value: 'otra', label: 'Otra' }
  ];

  const isDetailsRequired = alertType === 'cancelacion' || alertType === 'cambio';

  const handleSendAlert = () => {
    if (!alertType) {
      toast.error('Selecciona el tipo de alerta');
      return;
    }

    if (isDetailsRequired && !details.trim()) {
      toast.error('El motivo es obligatorio para este tipo de alerta');
      return;
    }

    // Enviar notificación a cocina
    const alertMessage = `Alerta: ${alertTypes.find(t => t.value === alertType)?.label} — Mesa ${tableNumber}${details ? ` — ${details}` : ''}`;
    
    addNotification({
      id: `alert-${Date.now()}`,
      type: 'kitchen_alert',
      title: `Nueva alerta de mesero`,
      message: alertMessage,
      priority: priority as 'normal' | 'urgent',
      fromRole: 'mesero',
      toRole: 'cocina',
      metadata: {
        alertType,
        orderId,
        tableNumber,
        waiterName,
        details,
        priority
      }
    });

    // Log de auditoría (simulado)
    console.log(`AUDIT_LOG: Alerta enviada por Mesero ${waiterName} — ${alertType} — ${details || 'Sin detalles'} — Mesa ${tableNumber} — ${new Date().toISOString()}`);

    toast.success('Alerta enviada a Cocina');
    
    // Limpiar formulario y cerrar
    setAlertType('');
    setDetails('');
    setPriority('normal');
    onClose();
  };

  const handleClose = () => {
    setAlertType('');
    setDetails('');
    setPriority('normal');
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-orange-500" />
            Enviar alerta a cocina
          </DialogTitle>
          <DialogDescription>
            Selecciona el tipo de alerta que deseas enviar al equipo de cocina
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Tipo de alerta */}
          <div className="space-y-2">
            <Label>Tipo de alerta *</Label>
            <Select value={alertType} onValueChange={setAlertType}>
              <SelectTrigger>
                <SelectValue placeholder="Selecciona el tipo de alerta" />
              </SelectTrigger>
              <SelectContent>
                {alertTypes.map((type) => (
                  <SelectItem key={type.value} value={type.value}>
                    {type.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Información de la orden */}
          <div className="p-3 bg-muted rounded-lg">
            <p className="text-sm">
              <span className="font-medium">Mesa:</span> {tableNumber}
            </p>
            {orderId && (
              <p className="text-sm">
                <span className="font-medium">Orden:</span> {orderId}
              </p>
            )}
          </div>

          {/* Detalles/Motivo */}
          <div className="space-y-2">
            <Label>
              Motivo / Detalle {isDetailsRequired && <span className="text-destructive">*</span>}
            </Label>
            <Textarea
              value={details}
              onChange={(e) => setDetails(e.target.value)}
              placeholder={
                alertType === 'cancelacion' 
                  ? 'Especifica el motivo de la cancelación...'
                  : alertType === 'cambio'
                  ? 'Describe los cambios necesarios...'
                  : 'Detalles adicionales (opcional)...'
              }
              rows={3}
            />
            {isDetailsRequired && (
              <p className="text-xs text-muted-foreground">
                Este campo es obligatorio para {alertTypes.find(t => t.value === alertType)?.label.toLowerCase()}
              </p>
            )}
          </div>

          {/* Prioridad */}
          <div className="space-y-2">
            <Label>Prioridad</Label>
            <RadioGroup value={priority} onValueChange={setPriority} className="flex gap-6">
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="normal" id="normal" />
                <Label htmlFor="normal">Normal</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="urgent" id="urgent" />
                <Label htmlFor="urgent">Urgente</Label>
              </div>
            </RadioGroup>
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
              onClick={handleSendAlert}
              className="flex-1"
              disabled={!alertType || (isDetailsRequired && !details.trim())}
            >
              <AlertTriangle className="h-4 w-4 mr-2" />
              Enviar alerta
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}