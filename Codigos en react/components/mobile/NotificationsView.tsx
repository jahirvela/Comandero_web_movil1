import React from 'react';
import { Button } from '../ui/button';
import { Card, CardContent } from '../ui/card';
import { Badge } from '../ui/badge';
import { ArrowLeft, CheckCircle, Info, AlertCircle, Clock, Flame } from 'lucide-react';

const getNotificationIcon = (type) => {
  switch (type) {
    case 'listo': return <CheckCircle className="h-4 w-4 text-green-600" />;
    case 'preparando': return <Clock className="h-4 w-4 text-orange-600" />;
    case 'info': return <Info className="h-4 w-4 text-blue-600" />;
    case 'urgente': return <AlertCircle className="h-4 w-4 text-red-600" />;
    case 'caliente': return <Flame className="h-4 w-4 text-red-500" />;
    case 'ticket_ready': return <CheckCircle className="h-4 w-4 text-green-600" />;
    default: return <Info className="h-4 w-4 text-gray-600" />;
  }
};

const getNotificationColor = (type) => {
  switch (type) {
    case 'listo': return 'border-l-green-500 bg-green-50';
    case 'preparando': return 'border-l-orange-500 bg-orange-50';
    case 'info': return 'border-l-blue-500 bg-blue-50';
    case 'urgente': return 'border-l-red-500 bg-red-50';
    case 'caliente': return 'border-l-red-500 bg-red-50';
    case 'ticket_ready': return 'border-l-green-500 bg-green-50';
    default: return 'border-l-gray-500 bg-gray-50';
  }
};

const getStatusText = (type) => {
  switch (type) {
    case 'listo': return 'Listo para servir';
    case 'preparando': return 'En preparación';
    case 'info': return 'Información';
    case 'urgente': return 'Urgente';
    case 'caliente': return 'Servir caliente';
    case 'ticket_ready': return 'Ticket listo para recoger';
    default: return 'Notificación';
  }
};

export function NotificationsView({ notifications, onBack }) {
  const allNotifications = [
    ...notifications,
    { id: 3, message: 'Mesa 5 - Tacos de barbacoa listos 🔥', time: '14:35', type: 'listo' },
    { id: 4, message: 'Mesa 2 - Consomé muy caliente, servir inmediatamente', time: '14:32', type: 'caliente' },
    { id: 5, message: 'Mesa 7 - Mix barbacoa en preparación', time: '14:28', type: 'preparando' },
    { id: 6, message: 'Se agotó la cebolla curtida', time: '14:15', type: 'urgente' },
    { id: 7, message: 'Mesa 3 - Pedido especial sin cilantro listo', time: '14:10', type: 'listo' },
    { id: 8, message: 'Turno matutino iniciado correctamente', time: '08:00', type: 'info' },
    { id: 9, message: 'Mesa 6 - Costilla en salsa preparándose', time: '14:20', type: 'preparando' },
    { id: 10, message: 'Ticket listo para recoger — Mesa 8', time: '15:10', type: 'ticket_ready' },
    { id: 11, message: 'Ticket listo para recoger — Mesa 3', time: '15:05', type: 'ticket_ready' }
  ].sort((a, b) => b.id - a.id);

  const urgentCount = allNotifications.filter(n => n.type === 'urgente').length;
  const readyCount = allNotifications.filter(n => n.type === 'listo').length;
  const preparingCount = allNotifications.filter(n => n.type === 'preparando').length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={onBack} className="text-amber-700 hover:bg-amber-100">
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h2 className="text-xl font-medium text-amber-900">Notificaciones</h2>
          <p className="text-sm text-amber-700">
            {allNotifications.length} notificaciones activas
          </p>
        </div>
      </div>

      {/* Filtros rápidos */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        <Badge variant="outline" className="whitespace-nowrap border-amber-300 text-amber-800">
          Todas ({allNotifications.length})
        </Badge>
        <Badge variant="outline" className="whitespace-nowrap text-green-600 border-green-300">
          🍽️ Listos ({readyCount})
        </Badge>
        <Badge variant="outline" className="whitespace-nowrap text-orange-600 border-orange-300">
          🔥 Preparando ({preparingCount})
        </Badge>
        <Badge variant="outline" className="whitespace-nowrap text-red-600 border-red-300">
          ⚠️ Urgentes ({urgentCount})
        </Badge>
      </div>

      {/* Resumen rápido */}
      {(urgentCount > 0 || readyCount > 0) && (
        <div className="grid grid-cols-2 gap-4">
          {readyCount > 0 && (
            <Card className="bg-green-50 border-green-200">
              <CardContent className="p-4 text-center">
                <div className="text-2xl font-medium text-green-700">{readyCount}</div>
                <div className="text-sm text-green-600">Platillos listos</div>
              </CardContent>
            </Card>
          )}
          {urgentCount > 0 && (
            <Card className="bg-red-50 border-red-200">
              <CardContent className="p-4 text-center">
                <div className="text-2xl font-medium text-red-700">{urgentCount}</div>
                <div className="text-sm text-red-600">Alertas urgentes</div>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {/* Lista de notificaciones */}
      <div className="space-y-3">
        {allNotifications.map(notification => (
          <Card 
            key={notification.id} 
            className={`border-l-4 ${getNotificationColor(notification.type)} transition-all duration-200 hover:shadow-md`}
          >
            <CardContent className="p-4">
              <div className="flex items-start gap-3">
                <div className="mt-0.5">
                  {getNotificationIcon(notification.type)}
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-amber-900">
                    {notification.message}
                  </p>
                  <div className="flex items-center justify-between mt-2">
                    <span className="text-xs text-amber-700">
                      {notification.time}
                    </span>
                    <Badge 
                      variant="outline" 
                      className={`text-xs ${
                        notification.type === 'listo' ? 'border-green-300 text-green-700 bg-green-50' :
                        notification.type === 'preparando' ? 'border-orange-300 text-orange-700 bg-orange-50' :
                        notification.type === 'urgente' ? 'border-red-300 text-red-700 bg-red-50' :
                        notification.type === 'caliente' ? 'border-red-300 text-red-700 bg-red-50' :
                        notification.type === 'ticket_ready' ? 'border-green-300 text-green-700 bg-green-50' :
                        'border-blue-300 text-blue-700 bg-blue-50'
                      }`}
                    >
                      {getStatusText(notification.type)}
                    </Badge>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Acciones */}
      <div className="flex gap-3">
        <Button variant="outline" className="flex-1 border-amber-300 text-amber-700 hover:bg-amber-100">
          Marcar todas como leídas
        </Button>
        <Button variant="outline" className="flex-1 border-orange-300 text-orange-700 hover:bg-orange-100">
          Limpiar notificaciones
        </Button>
      </div>

      {allNotifications.length === 0 && (
        <div className="text-center py-12 text-amber-700">
          <div className="w-16 h-16 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle className="h-8 w-8 text-amber-600" />
          </div>
          <p>No hay notificaciones</p>
          <p className="text-sm">Todas las órdenes están al día</p>
        </div>
      )}

      {/* Info del puesto */}
      <Card className="bg-gradient-to-r from-orange-100 to-red-100 border-orange-300">
        <CardContent className="p-4">
          <div className="text-center">
            <div className="text-sm text-orange-900 font-medium">🔥 Puesto Activo</div>
            <div className="text-xs text-orange-800 mt-1">
              Barbacoa fresca disponible • Horario: 8:00 AM - 6:00 PM
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}