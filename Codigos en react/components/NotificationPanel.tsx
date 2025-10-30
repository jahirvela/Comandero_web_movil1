import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { ScrollArea } from './ui/scroll-area';
import { Separator } from './ui/separator';
import { 
  Bell, 
  CheckCircle, 
  Clock, 
  AlertTriangle, 
  ChefHat,
  DollarSign,
  Users,
  X,
  BellOff,
  Calculator,
  AlertCircle
} from 'lucide-react';
import { useNotifications, Notification } from './NotificationContext';

interface NotificationPanelProps {
  userRole: string;
  userName?: string;
  isOpen: boolean;
  onClose: () => void;
}

export function NotificationPanel({ userRole, userName, isOpen, onClose }: NotificationPanelProps) {
  const { getNotificationsForUser, markAsRead, getUnreadCount } = useNotifications();
  const notifications = getNotificationsForUser(userRole, userName);
  const unreadCount = getUnreadCount(userRole, userName);

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'order_ready': return <ChefHat className="h-4 w-4 text-green-600" />;
      case 'payment_completed': return <DollarSign className="h-4 w-4 text-blue-600" />;
      case 'ticket_ready': return <CheckCircle className="h-4 w-4 text-purple-600" />;
      case 'new_order': return <Bell className="h-4 w-4 text-orange-600" />;
      case 'table_request': return <Users className="h-4 w-4 text-amber-600" />;
      case 'order_delayed': return <AlertTriangle className="h-4 w-4 text-red-600" />;
      case 'cash_close_verification': return <Calculator className="h-4 w-4 text-green-600" />;
      case 'cash_close_clarification': return <AlertCircle className="h-4 w-4 text-orange-600" />;
      default: return <Bell className="h-4 w-4 text-gray-600" />;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent': return 'border-red-500 bg-red-50';
      case 'high': return 'border-orange-500 bg-orange-50';
      case 'normal': return 'border-blue-500 bg-blue-50';
      case 'low': return 'border-gray-500 bg-gray-50';
      default: return 'border-gray-300 bg-white';
    }
  };

  const formatTimeAgo = (timestamp: Date) => {
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - timestamp.getTime()) / 60000);
    
    if (diffInMinutes < 1) return 'Ahora';
    if (diffInMinutes < 60) return `${diffInMinutes} min`;
    
    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) return `${diffInHours}h`;
    
    const diffInDays = Math.floor(diffInHours / 24);
    return `${diffInDays}d`;
  };

  const handleNotificationClick = (notification: Notification) => {
    if (!notification.read) {
      markAsRead(notification.id);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-start justify-end p-4">
      <Card className="w-full max-w-md h-[600px] border-amber-200 shadow-xl">
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2 text-amber-900">
              <Bell className="h-5 w-5" />
              Notificaciones
              {unreadCount > 0 && (
                <Badge className="bg-red-100 text-red-800 border-red-300">
                  {unreadCount}
                </Badge>
              )}
            </CardTitle>
            <Button variant="ghost" size="sm" onClick={onClose}>
              <X className="h-4 w-4" />
            </Button>
          </div>
        </CardHeader>
        
        <CardContent className="p-0">
          <ScrollArea className="h-[500px]">
            {notifications.length === 0 ? (
              <div className="p-6 text-center text-amber-600">
                <BellOff className="h-12 w-12 mx-auto mb-3 opacity-50" />
                <p>No tienes notificaciones</p>
                <p className="text-sm opacity-75">Las nuevas notificaciones aparecerán aquí</p>
              </div>
            ) : (
              <div className="space-y-2 p-4">
                {notifications.map((notification, index) => (
                  <div key={notification.id}>
                    <div
                      onClick={() => handleNotificationClick(notification)}
                      className={`p-3 rounded-lg border-l-4 cursor-pointer transition-colors hover:bg-amber-50 ${
                        getPriorityColor(notification.priority)
                      } ${!notification.read ? 'shadow-md' : 'opacity-75'}`}
                    >
                      <div className="flex items-start gap-3">
                        <div className="flex-shrink-0 mt-1">
                          {getNotificationIcon(notification.type)}
                        </div>
                        
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between mb-1">
                            <h4 className={`font-medium text-sm ${
                              !notification.read ? 'text-amber-900' : 'text-amber-700'
                            }`}>
                              {notification.title}
                            </h4>
                            <div className="flex items-center gap-1 text-xs text-amber-600">
                              <Clock className="h-3 w-3" />
                              {formatTimeAgo(notification.timestamp)}
                            </div>
                          </div>
                          
                          <p className="text-sm text-amber-700 mb-2">
                            {notification.message}
                          </p>
                          
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              {notification.tableNumber && (
                                <Badge variant="outline" className="text-xs border-amber-300">
                                  Mesa {notification.tableNumber}
                                </Badge>
                              )}
                              {notification.orderId && (
                                <Badge variant="outline" className="text-xs border-blue-300">
                                  {notification.orderId}
                                </Badge>
                              )}
                            </div>
                            
                            <div className="text-xs text-amber-600">
                              De: {notification.fromUser}
                            </div>
                          </div>
                          
                          {notification.priority === 'urgent' && (
                            <div className="flex items-center gap-1 mt-2 text-red-600">
                              <AlertTriangle className="h-3 w-3" />
                              <span className="text-xs font-medium">URGENTE</span>
                            </div>
                          )}
                        </div>
                        
                        {!notification.read && (
                          <div className="w-2 h-2 bg-red-500 rounded-full flex-shrink-0 mt-2"></div>
                        )}
                      </div>
                    </div>
                    
                    {index < notifications.length - 1 && (
                      <Separator className="my-2 border-amber-200" />
                    )}
                  </div>
                ))}
              </div>
            )}
          </ScrollArea>
        </CardContent>
      </Card>
    </div>
  );
}