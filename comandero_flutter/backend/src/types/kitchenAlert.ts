/**
 * Tipos para el nuevo sistema de alertas de cocina
 * 
 * Este módulo define los tipos y interfaces para el flujo de alertas
 * mesero → cocinero usando Socket.IO con rooms específicos.
 */

export type AlertType = 'NEW_ORDER' | 'UPDATE_ORDER' | 'CANCEL_ORDER' | 'EXTRA_ITEM';

export type StationType = 'tacos' | 'consomes' | 'bebidas' | 'general';

/**
 * Payload estándar para alertas de cocina
 */
export interface KitchenAlertPayload {
  id?: number;               // ID de la alerta en BD (opcional si aún no se guardó)
  orderId: number;
  tableId: number | null;    // null si es para llevar
  mesaCodigo?: string;       // Código visible de la mesa (ej: "1")
  station: StationType;
  type: AlertType;
  message: string;           // Mensaje descriptivo de la alerta
  createdByUserId: number;   // ID del usuario que genera la alerta (mesero o capitán)
  createdAt?: string;        // ISO string de la fecha de creación
  priority?: string;         // Prioridad: 'Normal' o 'Urgente'
  createdByUsername?: string; // Username del usuario que envía la alerta
  createdByRole?: string;     // Rol del usuario: 'mesero' o 'capitan'
}

/**
 * Payload para crear una alerta desde el frontend
 */
export interface CreateKitchenAlertRequest {
  orderId: number;
  tableId?: number | null;
  station?: StationType;
  type: AlertType;
  message: string;
  priority?: string;         // Prioridad: 'Normal' o 'Urgente'
}

