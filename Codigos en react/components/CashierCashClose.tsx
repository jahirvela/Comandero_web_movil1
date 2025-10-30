import React, { useState, useEffect } from 'react';
import { NewCashClose } from './admin/NewCashClose';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Alert, AlertDescription } from './ui/alert';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Textarea } from './ui/textarea';
import { Calculator, ArrowLeft, TrendingUp, AlertCircle, Bell } from 'lucide-react';
import { useNotifications } from './NotificationContext';
import { toast } from 'sonner@2.0.3';
import { mockCashierClosures } from './admin/cash-close/mockData';

interface CashierCashCloseProps {
  user: {
    id: string;
    name: string;
    type: string;
  };
  onBack: () => void;
}

export function CashierCashClose({ user, onBack }: CashierCashCloseProps) {
  const { notifications, getNotificationsForUser } = useNotifications();
  const [clarificationRequests, setClarificationRequests] = useState<any[]>([]);
  const [selectedNotification, setSelectedNotification] = useState<any>(null);
  const [isResponseDialogOpen, setIsResponseDialogOpen] = useState(false);
  const [responseText, setResponseText] = useState('');

  // Filtrar notificaciones de aclaración para este cajero
  useEffect(() => {
    const cashierNotifications = getNotificationsForUser('cajero', user.name);
    const clarifications = cashierNotifications.filter(n => 
      n.type === 'cash_close_clarification' && !n.read
    );
    setClarificationRequests(clarifications);
  }, [notifications, user.name, getNotificationsForUser]);

  const handleResponseToClarification = (notification: any) => {
    setSelectedNotification(notification);
    setIsResponseDialogOpen(true);
  };

  const handleSubmitResponse = async () => {
    if (!selectedNotification || !responseText.trim()) return;

    try {
      // Simular respuesta del cajero
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Actualizar el cierre con la respuesta
      const closureIndex = mockCashierClosures.findIndex(c => c.id === selectedNotification.closureId);
      if (closureIndex !== -1) {
        mockCashierClosures[closureIndex].auditLog.push({
          id: `log_${Date.now()}`,
          timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
          action: 'aclaración_enviada',
          usuario: user.name,
          mensaje: `Respuesta del cajero: ${responseText}`
        });
        
        // Cambiar estado a pendiente verificación
        mockCashierClosures[closureIndex].estado = 'Pendiente verificación';
      }

      toast("Respuesta enviada al Admin");
      setIsResponseDialogOpen(false);
      setResponseText('');
      setSelectedNotification(null);
      
      // Marcar notificación como leída
      setClarificationRequests(prev => 
        prev.filter(n => n.id !== selectedNotification.id)
      );
    } catch (error) {
      toast("Error al enviar respuesta");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-purple-50">
      {/* Header */}
      <header className="bg-white border-b border-blue-200 shadow-sm">
        <div className="px-3 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Button
                variant="outline"
                size="sm"
                onClick={onBack}
                className="border-blue-300 text-blue-700"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Volver a Caja
              </Button>
              <div>
                <h1 className="text-base font-medium text-blue-900">
                  Historial de Cierres de Caja
                </h1>
                <p className="text-sm text-blue-700">{user.name} • Cajero</p>
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              <Badge className="bg-blue-100 text-blue-800 border-blue-300">
                <Calculator className="h-3 w-3 mr-1" />
                Mis Cierres
              </Badge>
            </div>
          </div>
        </div>
      </header>

      <div className="p-4">
        {/* Alertas de aclaración pendientes */}
        {clarificationRequests.length > 0 && (
          <div className="mb-6 space-y-3">
            {clarificationRequests.map((notification) => (
              <Alert key={notification.id} className="border-orange-300 bg-orange-50">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription className="flex items-center justify-between">
                  <div>
                    <p className="font-medium text-orange-900">{notification.title}</p>
                    <p className="text-sm text-orange-800 mt-1">{notification.message}</p>
                    {notification.clarificationReason && (
                      <p className="text-sm text-orange-700 mt-2 italic">
                        Motivo: {notification.clarificationReason}
                      </p>
                    )}
                  </div>
                  <Button 
                    size="sm"
                    onClick={() => handleResponseToClarification(notification)}
                    className="bg-orange-600 hover:bg-orange-700 text-white ml-4"
                  >
                    Responder
                  </Button>
                </AlertDescription>
              </Alert>
            ))}
          </div>
        )}

        {/* Resumen rápido del cajero */}
        <Card className="border-blue-200 mb-6">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-blue-900">
              <TrendingUp className="h-5 w-5" />
              Resumen de Mis Cierres
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="text-center p-3 bg-green-50 rounded border border-green-200">
                <p className="text-sm text-green-700">Cierres Este Mes</p>
                <p className="text-2xl font-medium text-green-800">15</p>
              </div>
              <div className="text-center p-3 bg-blue-50 rounded border border-blue-200">
                <p className="text-sm text-blue-700">Cierres Verificados</p>
                <p className="text-2xl font-medium text-blue-800">12</p>
              </div>
              <div className="text-center p-3 bg-amber-50 rounded border border-amber-200">
                <p className="text-sm text-amber-700">Pendientes</p>
                <p className="text-2xl font-medium text-amber-800">3</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Componente principal de cierres con rol de cajero */}
        <NewCashClose userRole="cajero" userId={user.name} />
      </div>

      {/* Modal de respuesta a aclaración */}
      <Dialog open={isResponseDialogOpen} onOpenChange={setIsResponseDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Responder a solicitud de aclaración</DialogTitle>
            <DialogDescription>
              Proporciona la aclaración solicitada por el administrador
            </DialogDescription>
          </DialogHeader>
          
          {selectedNotification && (
            <div className="space-y-4">
              <div className="p-3 bg-orange-50 rounded-md border border-orange-200">
                <p className="text-sm text-orange-800">
                  <strong>Motivo de la solicitud:</strong> {selectedNotification.clarificationReason}
                </p>
              </div>
              
              <div>
                <label className="text-sm font-medium">Tu respuesta</label>
                <Textarea
                  placeholder="Proporciona la aclaración solicitada..."
                  value={responseText}
                  onChange={(e) => setResponseText(e.target.value)}
                  className="mt-1"
                  rows={4}
                />
              </div>
            </div>
          )}
          
          <div className="flex justify-end gap-3">
            <Button 
              variant="outline" 
              onClick={() => {
                setIsResponseDialogOpen(false);
                setResponseText('');
                setSelectedNotification(null);
              }}
            >
              Cancelar
            </Button>
            <Button 
              onClick={handleSubmitResponse}
              disabled={!responseText.trim()}
              className="bg-orange-600 hover:bg-orange-700"
            >
              Enviar Respuesta
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}