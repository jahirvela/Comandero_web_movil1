import React from 'react';
import { Button } from './ui/button';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { toast } from 'sonner@2.0.3';
import { useNotifications } from './NotificationContext';
import { mockCashierClosures } from './admin/cash-close/mockData';
import { Beaker, PlayCircle, TestTube } from 'lucide-react';

export function TestCashCloseFlow() {
  const { addNotification } = useNotifications();

  const simulateCashierSendsClosure = () => {
    // Simular que un cajero envía un cierre
    const newClosure = {
      id: `test_close_${Date.now()}`,
      fecha: new Date().toISOString().slice(0, 19).replace('T', ' '),
      periodo: 'Día',
      usuario: 'Ana Rodríguez (TEST)',
      totalNeto: 3500.00,
      efectivo: 3200.00,
      tarjeta: 800.00,
      propinasTarjeta: 120.00,
      propinasEfectivo: 150.00,
      pedidosParaLlevar: 1000.00,
      estado: 'Pendiente verificación' as const,
      efectivoContado: 3200.00,
      totalTarjeta: 800.00,
      otrosIngresos: 50.00,
      otrosIngresosTexto: 'Propina extra de cliente VIP',
      notaCajero: 'Día normal, todo correcto. Cliente VIP dejó propina extra.',
      totalDeclarado: 4050.00,
      auditLog: [{
        id: `log_${Date.now()}`,
        timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
        action: 'enviado' as const,
        usuario: 'Ana Rodríguez (TEST)',
        mensaje: 'Cierre enviado por Ana Rodríguez (TEST)'
      }]
    };

    // Agregar a mock data
    mockCashierClosures.unshift(newClosure);

    // Notificar al Admin
    addNotification({
      type: 'cash_close_verification',
      title: 'Nuevo cierre de caja recibido (TEST)',
      message: 'Ana Rodríguez (TEST) ha enviado un cierre de caja para verificación',
      targetRole: 'admin',
      fromUser: 'Ana Rodríguez (TEST)',
      fromRole: 'cajero',
      closureId: newClosure.id,
      priority: 'normal'
    });

    toast("✅ Simulación completada: Cajero envió cierre de caja");
  };

  const simulateAdminRequestsClarification = () => {
    // Buscar el primer cierre pendiente para solicitar aclaración
    const pendingClosure = mockCashierClosures.find(c => c.estado === 'Pendiente verificación');
    
    if (!pendingClosure) {
      toast("❌ No hay cierres pendientes para solicitar aclaración");
      return;
    }

    // Actualizar estado del cierre
    const closureIndex = mockCashierClosures.findIndex(c => c.id === pendingClosure.id);
    if (closureIndex !== -1) {
      mockCashierClosures[closureIndex].estado = 'Aclaración requerida';
      mockCashierClosures[closureIndex].auditLog.push({
        id: `log_${Date.now()}`,
        timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
        action: 'aclaración_solicitada',
        usuario: 'Admin (TEST)',
        mensaje: 'Aclaración solicitada por Admin (TEST)',
        motivo: 'Hay una diferencia de $50 en otros ingresos. ¿Puedes confirmar el origen de esta cantidad?'
      });
    }

    // Notificar al cajero
    addNotification({
      type: 'cash_close_clarification',
      title: 'Aclaración solicitada para cierre (TEST)',
      message: `Aclaración solicitada para cierre del ${pendingClosure.fecha.split(' ')[0]} — motivo: Diferencia en otros ingresos`,
      targetRole: 'cajero',
      targetUser: pendingClosure.usuario,
      fromUser: 'Admin (TEST)',
      fromRole: 'admin',
      closureId: pendingClosure.id,
      clarificationReason: 'Hay una diferencia de $50 en otros ingresos. ¿Puedes confirmar el origen de esta cantidad?',
      priority: 'normal'
    });

    toast("✅ Simulación completada: Admin solicitó aclaración");
  };

  const simulateCashierResponds = () => {
    // Buscar el primer cierre que requiere aclaración
    const clarificationClosure = mockCashierClosures.find(c => c.estado === 'Aclaración requerida');
    
    if (!clarificationClosure) {
      toast("❌ No hay cierres que requieran aclaración");
      return;
    }

    // Actualizar con respuesta del cajero
    const closureIndex = mockCashierClosures.findIndex(c => c.id === clarificationClosure.id);
    if (closureIndex !== -1) {
      mockCashierClosures[closureIndex].estado = 'Pendiente verificación';
      mockCashierClosures[closureIndex].auditLog.push({
        id: `log_${Date.now()}`,
        timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
        action: 'aclaración_enviada',
        usuario: clarificationClosure.usuario,
        mensaje: 'Respuesta del cajero: Los $50 adicionales corresponden a una propina extra que dejó un cliente VIP en efectivo al final del turno.'
      });
    }

    toast("✅ Simulación completada: Cajero respondió a la aclaración");
  };

  const simulateAdminVerifies = () => {
    // Buscar el primer cierre pendiente
    const pendingClosure = mockCashierClosures.find(c => c.estado === 'Pendiente verificación');
    
    if (!pendingClosure) {
      toast("❌ No hay cierres pendientes para verificar");
      return;
    }

    // Verificar el cierre
    const closureIndex = mockCashierClosures.findIndex(c => c.id === pendingClosure.id);
    if (closureIndex !== -1) {
      mockCashierClosures[closureIndex].estado = 'Verificado';
      mockCashierClosures[closureIndex].auditLog.push({
        id: `log_${Date.now()}`,
        timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
        action: 'verificado',
        usuario: 'Admin (TEST)',
        mensaje: `Verificado por Admin (TEST) — ${new Date().toISOString().slice(0, 19).replace('T', ' ')}`
      });
    }

    toast("✅ Simulación completada: Admin verificó el cierre");
  };

  return (
    <Card className="border-amber-200 bg-amber-50">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-amber-900">
          <TestTube className="h-5 w-5" />
          Simulador del Flujo de Cierre de Caja
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-amber-700">
          Usa estos botones para simular el flujo completo del sistema de cierres de caja:
        </p>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <Button 
            onClick={simulateCashierSendsClosure}
            variant="outline"
            className="justify-start border-blue-300 text-blue-700 hover:bg-blue-50"
          >
            <PlayCircle className="h-4 w-4 mr-2" />
            1. Cajero envía cierre
          </Button>
          
          <Button 
            onClick={simulateAdminRequestsClarification}
            variant="outline"
            className="justify-start border-orange-300 text-orange-700 hover:bg-orange-50"
          >
            <PlayCircle className="h-4 w-4 mr-2" />
            2. Admin solicita aclaración
          </Button>
          
          <Button 
            onClick={simulateCashierResponds}
            variant="outline"
            className="justify-start border-purple-300 text-purple-700 hover:bg-purple-50"
          >
            <PlayCircle className="h-4 w-4 mr-2" />
            3. Cajero responde
          </Button>
          
          <Button 
            onClick={simulateAdminVerifies}
            variant="outline"
            className="justify-start border-green-300 text-green-700 hover:bg-green-50"
          >
            <PlayCircle className="h-4 w-4 mr-2" />
            4. Admin verifica
          </Button>
        </div>
        
        <div className="text-xs text-amber-600 bg-amber-100 p-2 rounded">
          <strong>Instrucciones:</strong> Ejecuta los pasos en orden. Después de cada paso, verifica las notificaciones y navega a "Revisar Cierres de Cajeros" para ver los cambios en tiempo real.
        </div>
      </CardContent>
    </Card>
  );
}