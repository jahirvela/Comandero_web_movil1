import { getIO, getSocketRooms } from './socket.js';
import type { OrdenDetalle } from '../types/ordenes.js';
import { emitirAlertaCancelacion, emitirAlertaModificacion } from '../modules/alertas/alertas.service.js';
import { logger } from '../config/logger.js';

// Re-exportar logger para uso en controladores
export { logger };

// Eventos para pagos
export const emitPaymentCreated = (pago: any) => {
  const io = getIO();
  io.emit('pago.creado', pago);
  io.to(getSocketRooms.role('cajero')).emit('pago.creado', pago);
  io.to(getSocketRooms.role('administrador')).emit('pago.creado', pago);
  io.to(getSocketRooms.role('capitan')).emit('pago.creado', pago);
};

export const emitPaymentUpdated = (pago: any) => {
  const io = getIO();
  io.emit('pago.actualizado', pago);
  io.to(getSocketRooms.role('cajero')).emit('pago.actualizado', pago);
  io.to(getSocketRooms.role('administrador')).emit('pago.actualizado', pago);
  io.to(getSocketRooms.role('capitan')).emit('pago.actualizado', pago);
};

// Eventos para mesas
export const emitTableUpdated = (mesa: any) => {
  const io = getIO();
  io.emit('mesa.actualizada', mesa);
  io.to(getSocketRooms.role('mesero')).emit('mesa.actualizada', mesa);
  io.to(getSocketRooms.role('capitan')).emit('mesa.actualizada', mesa);
  io.to(getSocketRooms.role('administrador')).emit('mesa.actualizada', mesa);
};

export const emitTableCreated = (mesa: any) => {
  const io = getIO();
  io.emit('mesa.creada', mesa);
  io.to(getSocketRooms.role('mesero')).emit('mesa.creada', mesa);
  io.to(getSocketRooms.role('capitan')).emit('mesa.creada', mesa);
  io.to(getSocketRooms.role('administrador')).emit('mesa.creada', mesa);
};

export const emitTableDeleted = (mesaId: number) => {
  const io = getIO();
  io.emit('mesa.eliminada', { id: mesaId });
  io.to(getSocketRooms.role('mesero')).emit('mesa.eliminada', { id: mesaId });
  io.to(getSocketRooms.role('capitan')).emit('mesa.eliminada', { id: mesaId });
  io.to(getSocketRooms.role('administrador')).emit('mesa.eliminada', { id: mesaId });
};

// Evento para alertas de pago (cuando una orden se marca como pagada)
export const emitPaymentAlert = (ordenId: number, total: number) => {
  const io = getIO();
  io.emit('alerta.pago', { ordenId, total });
  io.to(getSocketRooms.role('cajero')).emit('alerta.pago', { ordenId, total });
  io.to(getSocketRooms.role('administrador')).emit('alerta.pago', { ordenId, total });
};

// Evento para notificar al cajero cuando se envía una cuenta
export const emitBillSent = (bill: any) => {
  const io = getIO();
  io.to(getSocketRooms.role('cajero')).emit('cuenta.enviada', bill);
  io.to(getSocketRooms.role('administrador')).emit('cuenta.enviada', bill);
  io.to(getSocketRooms.role('capitan')).emit('cuenta.enviada', bill);
};

export const emitOrderCreated = (orden: OrdenDetalle) => {
  const io = getIO();
  // Emitir a todos (incluye administrador)
  io.emit('pedido.creado', orden);
  // Emitir a roles específicos
  if (orden.mesaCodigo) {
    io.to(getSocketRooms.role('capitan')).emit('pedido.creado', orden);
    io.to(getSocketRooms.role('mesero')).emit('pedido.creado', orden);
  }
  io.to(getSocketRooms.role('cocinero')).emit('pedido.creado', orden);
  io.to(getSocketRooms.role('administrador')).emit('pedido.creado', orden);
};

export const emitOrderUpdated = async (
  orden: OrdenDetalle,
  usuarioId?: number,
  username?: string,
  rol?: string,
  cambio?: string
) => {
  const io = getIO();
  // Emitir a todos (incluye administrador)
  io.emit('pedido.actualizado', orden);
  io.to(`orden:${orden.id}`).emit('pedido.actualizado', orden);
  // Emitir a roles específicos
  io.to(getSocketRooms.role('cocinero')).emit('pedido.actualizado', orden);
  io.to(getSocketRooms.role('mesero')).emit('pedido.actualizado', orden);
  io.to(getSocketRooms.role('capitan')).emit('pedido.actualizado', orden);
  io.to(getSocketRooms.role('administrador')).emit('pedido.actualizado', orden);

  // Si hay cambio y usuario, emitir alerta de modificación
  if (cambio && usuarioId && username && rol) {
    await emitirAlertaModificacion(
      orden.id,
      orden.items[0]?.productoId || 0,
      cambio,
      usuarioId,
      username,
      rol
    );
  }
};

export const emitOrderCancelled = async (
  orden: OrdenDetalle,
  motivo: string,
  usuarioId?: number,
  username?: string,
  rol?: string
) => {
  const io = getIO();
  // Emitir a todos (incluye administrador)
  io.emit('pedido.cancelado', orden);
  // Emitir a roles específicos
  io.to(getSocketRooms.role('cocinero')).emit('pedido.cancelado', orden);
  io.to(getSocketRooms.role('mesero')).emit('pedido.cancelado', orden);
  io.to(getSocketRooms.role('capitan')).emit('pedido.cancelado', orden);
  io.to(getSocketRooms.role('administrador')).emit('pedido.cancelado', orden);

  // Emitir alerta de cancelación
  if (usuarioId && username && rol) {
    await emitirAlertaCancelacion(orden.id, motivo, usuarioId, username, rol);
  }
};

// Eventos para tickets
export const emitTicketCreated = (ticket: any) => {
  const io = getIO();
  logger.info({ ticketId: ticket.id }, 'Emitiendo evento ticket.creado');
  io.emit('ticket.creado', ticket);
  io.to(getSocketRooms.role('cajero')).emit('ticket.creado', ticket);
  io.to(getSocketRooms.role('administrador')).emit('ticket.creado', ticket);
  io.to(getSocketRooms.role('capitan')).emit('ticket.creado', ticket);
};

export const emitTicketPrinted = (ticket: any) => {
  const io = getIO();
  logger.info({ ticketId: ticket.id }, 'Emitiendo evento ticket.impreso');
  io.emit('ticket.impreso', ticket);
  io.to(getSocketRooms.role('cajero')).emit('ticket.impreso', ticket);
  io.to(getSocketRooms.role('administrador')).emit('ticket.impreso', ticket);
  io.to(getSocketRooms.role('capitan')).emit('ticket.impreso', ticket);
};

export const emitTicketUpdated = (ticket: any) => {
  const io = getIO();
  logger.info({ ticketId: ticket.id }, 'Emitiendo evento ticket.actualizado');
  io.emit('ticket.actualizado', ticket);
  io.to(getSocketRooms.role('cajero')).emit('ticket.actualizado', ticket);
  io.to(getSocketRooms.role('administrador')).emit('ticket.actualizado', ticket);
  io.to(getSocketRooms.role('capitan')).emit('ticket.actualizado', ticket);
};

// Eventos para cierres de caja
export const emitCashClosureCreated = (cierre: any) => {
  const io = getIO();
  logger.info({ cierreId: cierre.id }, 'Emitiendo evento cierre.creado');
  io.emit('cierre.creado', cierre);
  io.to(getSocketRooms.role('cajero')).emit('cierre.creado', cierre);
  io.to(getSocketRooms.role('administrador')).emit('cierre.creado', cierre);
  io.to(getSocketRooms.role('capitan')).emit('cierre.creado', cierre);
};

export const emitCashClosureUpdated = (cierre: any) => {
  const io = getIO();
  logger.info({ cierreId: cierre.id }, 'Emitiendo evento cierre.actualizado');
  io.emit('cierre.actualizado', cierre);
  io.to(getSocketRooms.role('cajero')).emit('cierre.actualizado', cierre);
  io.to(getSocketRooms.role('administrador')).emit('cierre.actualizado', cierre);
  io.to(getSocketRooms.role('capitan')).emit('cierre.actualizado', cierre);
};

