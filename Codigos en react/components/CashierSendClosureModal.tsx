import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Textarea } from './ui/textarea';
import { Card, CardContent } from './ui/card';
import { DollarSign, CreditCard, Coins, Send } from 'lucide-react';
import { toast } from 'sonner@2.0.3';
import { useNotifications } from './NotificationContext';
import { mockCashierClosures } from './admin/cash-close/mockData';

interface CashierSendClosureModalProps {
  isOpen: boolean;
  onClose: () => void;
  cashier: {
    id: string;
    name: string;
  };
}

export function CashierSendClosureModal({ isOpen, onClose, cashier }: CashierSendClosureModalProps) {
  const { addNotification } = useNotifications();
  
  const [formData, setFormData] = useState({
    efectivoContado: '',
    totalTarjeta: '',
    otrosIngresos: '',
    otrosIngresosTexto: '',
    notaCajero: ''
  });
  
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const calculateTotal = () => {
    const efectivo = parseFloat(formData.efectivoContado) || 0;
    const tarjeta = parseFloat(formData.totalTarjeta) || 0;
    const otros = parseFloat(formData.otrosIngresos) || 0;
    return efectivo + tarjeta + otros;
  };

  const handleSubmit = async () => {
    // Validaciones
    if (!formData.efectivoContado || !formData.totalTarjeta) {
      toast("Por favor completa los campos obligatorios");
      return;
    }

    const efectivo = parseFloat(formData.efectivoContado);
    const tarjeta = parseFloat(formData.totalTarjeta);
    const otros = parseFloat(formData.otrosIngresos) || 0;

    if (efectivo < 0 || tarjeta < 0 || otros < 0) {
      toast("Los montos no pueden ser negativos");
      return;
    }

    setIsSubmitting(true);

    try {
      // Simular envío a API
      await new Promise(resolve => setTimeout(resolve, 1500));

      // Crear nuevo cierre en mock data
      const newClosure = {
        id: `close_${Date.now()}_${cashier.name.replace(' ', '_').toLowerCase()}`,
        fecha: new Date().toISOString().slice(0, 19).replace('T', ' '),
        periodo: 'Día',
        usuario: cashier.name,
        totalNeto: calculateTotal(),
        efectivo: efectivo,
        tarjeta: tarjeta,
        propinasTarjeta: 0,
        propinasEfectivo: 0,
        pedidosParaLlevar: 0,
        estado: 'Pendiente verificación' as const,
        efectivoContado: efectivo,
        totalTarjeta: tarjeta,
        otrosIngresos: otros,
        otrosIngresosTexto: formData.otrosIngresosTexto,
        notaCajero: formData.notaCajero,
        totalDeclarado: calculateTotal(),
        auditLog: [{
          id: `log_${Date.now()}`,
          timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
          action: 'enviado' as const,
          usuario: cashier.name,
          mensaje: `Cierre enviado por ${cashier.name}`
        }]
      };

      // Agregar a mock data
      mockCashierClosures.unshift(newClosure);

      // Enviar notificación al Admin
      addNotification({
        type: 'cash_close_verification',
        title: 'Nuevo cierre de caja recibido',
        message: `${cashier.name} ha enviado un cierre de caja para verificación`,
        targetRole: 'admin',
        fromUser: cashier.name,
        fromRole: 'cajero',
        closureId: newClosure.id,
        priority: 'normal'
      });

      toast("Cierre enviado correctamente al Admin");
      
      // Reset form
      setFormData({
        efectivoContado: '',
        totalTarjeta: '',
        otrosIngresos: '',
        otrosIngresosTexto: '',
        notaCajero: ''
      });
      
      onClose();
    } catch (error) {
      toast("Error al enviar el cierre");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      setFormData({
        efectivoContado: '',
        totalTarjeta: '',
        otrosIngresos: '',
        otrosIngresosTexto: '',
        notaCajero: ''
      });
      onClose();
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md lg:max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Enviar Cierre de Caja</DialogTitle>
          <DialogDescription>
            Completa la información del cierre de caja para enviar al Admin
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Campos obligatorios */}
          <div className="grid grid-cols-1 gap-4">
            <div>
              <label className="text-sm font-medium text-amber-900 mb-2 block">
                Efectivo contado hoy *
              </label>
              <div className="relative">
                <DollarSign className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-amber-600" />
                <Input
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={formData.efectivoContado}
                  onChange={(e) => handleInputChange('efectivoContado', e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>

            <div>
              <label className="text-sm font-medium text-amber-900 mb-2 block">
                Total tarjeta *
              </label>
              <div className="relative">
                <CreditCard className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-amber-600" />
                <Input
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={formData.totalTarjeta}
                  onChange={(e) => handleInputChange('totalTarjeta', e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>

            <div>
              <label className="text-sm font-medium text-amber-900 mb-2 block">
                Otros ingresos
              </label>
              <div className="relative">
                <Coins className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-amber-600" />
                <Input
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={formData.otrosIngresos}
                  onChange={(e) => handleInputChange('otrosIngresos', e.target.value)}
                  className="pl-10"
                />
              </div>
              <Input
                placeholder="Describe los otros ingresos (opcional)"
                value={formData.otrosIngresosTexto}
                onChange={(e) => handleInputChange('otrosIngresosTexto', e.target.value)}
                className="mt-2"
              />
            </div>
          </div>

          {/* Total calculado */}
          <Card className="bg-amber-50 border-amber-200">
            <CardContent className="p-4">
              <div className="flex justify-between items-center">
                <span className="font-medium text-amber-900">Total declarado:</span>
                <span className="text-xl font-medium text-amber-900">
                  ${calculateTotal().toFixed(2)}
                </span>
              </div>
            </CardContent>
          </Card>

          {/* Nota del cajero */}
          <div>
            <label className="text-sm font-medium text-amber-900 mb-2 block">
              Nota (opcional)
            </label>
            <Textarea
              placeholder="Agrega cualquier observación sobre el cierre..."
              value={formData.notaCajero}
              onChange={(e) => handleInputChange('notaCajero', e.target.value)}
              rows={3}
            />
          </div>

          {/* Botones */}
          <div className="flex gap-3 pt-4">
            <Button 
              variant="outline" 
              onClick={handleClose}
              disabled={isSubmitting}
              className="flex-1"
            >
              Cancelar
            </Button>
            <Button 
              onClick={handleSubmit}
              disabled={isSubmitting || !formData.efectivoContado || !formData.totalTarjeta}
              className="flex-1 bg-blue-600 hover:bg-blue-700"
            >
              {isSubmitting ? (
                'Enviando...'
              ) : (
                <>
                  <Send className="h-4 w-4 mr-2" />
                  Enviar Cierre
                </>
              )}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}