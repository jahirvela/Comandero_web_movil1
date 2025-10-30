import React from 'react';
import { Card, CardContent } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { AlertTriangle, Clock, Eye } from 'lucide-react';

interface DelayAlert {
  id: string;
  type: 'demora' | 'cancelacion' | 'cambio';
  orderId: string;
  tableNumber?: number;
  isTakeaway?: boolean;
  customerName?: string;
  reason: string;
  reportedAt: Date;
  reportedBy: string;
  isRead?: boolean;
}

interface DelayAlertCardProps {
  alert: DelayAlert;
  onViewDetails: (alert: DelayAlert) => void;
  onMarkAsRead?: (alertId: string) => void;
}

export function DelayAlertCard({ alert, onViewDetails, onMarkAsRead }: DelayAlertCardProps) {
  const getTypeColor = (type: string) => {
    switch (type) {
      case 'demora':
        return 'bg-amber-100 text-amber-800 border-amber-300';
      case 'cancelacion':
        return 'bg-red-100 text-red-800 border-red-300';
      case 'cambio':
        return 'bg-blue-100 text-blue-800 border-blue-300';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const getTypeIcon = (type: string) => {
    return <AlertTriangle className="h-4 w-4" />;
  };

  const getLocationText = () => {
    if (alert.isTakeaway) {
      return `Solo para llevar${alert.customerName ? ` (${alert.customerName})` : ''}`;
    }
    return `Mesa ${alert.tableNumber}`;
  };

  const getElapsedTime = () => {
    const elapsed = Math.floor((Date.now() - alert.reportedAt.getTime()) / 60000);
    return `${elapsed} min`;
  };

  const borderColor = alert.type === 'cancelacion' ? 'border-red-300 border-2' : 
                     alert.type === 'demora' ? 'border-amber-300 border-2' : 'border-blue-300';

  return (
    <Card className={`${borderColor} ${!alert.isRead ? 'bg-yellow-50' : 'bg-gray-50'}`}>
      <CardContent className="p-3">
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-start gap-2">
            <div className="mt-1">
              {getTypeIcon(alert.type)}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap mb-1">
                <Badge className={getTypeColor(alert.type)}>
                  {alert.type.charAt(0).toUpperCase() + alert.type.slice(1)}
                </Badge>
                <span className="text-sm font-medium text-gray-900">
                  {alert.orderId}
                </span>
                <span className="text-sm text-gray-600">
                  {getLocationText()}
                </span>
              </div>
              
              <p className="text-sm text-gray-700 mb-2">
                {alert.reason}
              </p>
              
              <div className="flex items-center gap-4 text-xs text-gray-500">
                <div className="flex items-center gap-1">
                  <Clock className="h-3 w-3" />
                  Hace {getElapsedTime()}
                </div>
                <div>
                  Por: {alert.reportedBy}
                </div>
              </div>
            </div>
          </div>
          
          <div className="flex flex-col gap-1">
            <Button
              variant="outline"
              size="sm"
              onClick={() => onViewDetails(alert)}
              className="text-xs"
            >
              <Eye className="h-3 w-3 mr-1" />
              Ver detalles
            </Button>
            
            {!alert.isRead && onMarkAsRead && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => onMarkAsRead(alert.id)}
                className="text-xs"
              >
                Marcar como leído
              </Button>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}