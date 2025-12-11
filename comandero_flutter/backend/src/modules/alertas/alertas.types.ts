/**
 * Tipos de alertas en tiempo real
 */
export enum TipoAlerta {
  DEMORA = 'alerta.demora',
  CANCELACION = 'alerta.cancelacion',
  MODIFICACION = 'alerta.modificacion',
  CAJA = 'alerta.caja',
  COCINA = 'alerta.cocina',
  MESA = 'alerta.mesa',
  PAGO = 'alerta.pago'
}

export interface AlertaPayload {
  tipo: TipoAlerta;
  mensaje: string;
  ordenId?: number;
  mesaId?: number;
  productoId?: number;
  prioridad?: 'baja' | 'media' | 'alta' | 'urgente';
  estacion?: string;
  emisor: {
    id: number;
    username: string;
    rol: string;
  };
  timestamp: string;
  metadata?: Record<string, unknown>;
}

export interface AlertaDB {
  id: number;
  tipo: string;
  mensaje: string;
  ordenId: number | null;
  mesaId: number | null;
  productoId: number | null;
  prioridad?: string;
  estacion?: string | null;
  creadoPorUsuarioId: number;
  leido: boolean;
  leidoPorUsuarioId?: number | null;
  leidoEn?: Date | null;
  creadoEn: Date;
  metadata?: Record<string, unknown> | null;
}

