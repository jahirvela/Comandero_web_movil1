import {
  listarPagos,
  obtenerPagoPorId,
  crearPago,
  listarFormasPago,
  listarPropinas,
  registrarPropina,
  obtenerTotalPagado
} from './pagos.repository.js';
import type { CrearPagoInput, CrearPropinaInput } from './pagos.schemas.js';
import { notFound, badRequest } from '../../utils/http-error.js';
import {
  obtenerOrdenBasePorId,
  actualizarEstadoOrden,
  obtenerEstadoOrdenPorNombre
} from '../ordenes/ordenes.repository.js';
import { emitPaymentCreated, emitPaymentAlert, emitTicketCreated, emitOrderUpdated } from '../../realtime/events.js';
import { obtenerOrdenDetalle } from '../ordenes/ordenes.service.js';
import { nowMxISO } from '../../config/time.js';

export const obtenerPagos = (ordenId?: number) => listarPagos(ordenId);

export const obtenerPago = async (id: number) => {
  const pago = await obtenerPagoPorId(id);
  if (!pago) {
    throw notFound('Pago no encontrado');
  }
  return pago;
};

export const crearNuevoPago = async (input: CrearPagoInput, usuarioId?: number) => {
  const orden = await obtenerOrdenBasePorId(input.ordenId);
  if (!orden) {
    throw notFound('Orden no encontrada');
  }

  const formas = await listarFormasPago();
  if (!formas.some((forma) => forma.id === input.formaPagoId)) {
    throw badRequest('Forma de pago inválida');
  }

  const pagoId = await crearPago({
    ordenId: input.ordenId,
    formaPagoId: input.formaPagoId,
    monto: input.monto,
    referencia: input.referencia ?? null,
    estado: input.estado ?? 'aplicado',
    fechaPago: input.fechaPago ?? null,
    empleadoId: usuarioId ?? null
  });

  const pago = await obtenerPago(pagoId);
  
  // Emitir evento de pago creado
  emitPaymentCreated(pago);
  
  if ((input.estado ?? 'aplicado') === 'aplicado') {
    const totalPagado = await obtenerTotalPagado(input.ordenId);
    if (totalPagado >= orden.total) {
      const estadoPagada = await obtenerEstadoOrdenPorNombre('pagada');
      if (estadoPagada) {
        await actualizarEstadoOrden(input.ordenId, estadoPagada.id, usuarioId ?? null);
        
        // Obtener orden actualizada para emitir eventos
        const ordenActualizada = await obtenerOrdenDetalle(input.ordenId);
        
        // Emitir evento de orden actualizada para que el mesero actualice su historial
        await emitOrderUpdated(ordenActualizada, usuarioId, pago?.empleadoNombre || 'Cajero', 'cajero', 'Orden pagada');
        
        // Emitir alerta de pago cuando la orden se marca como pagada
        emitPaymentAlert(input.ordenId, orden.total);
        
        // Emitir evento de ticket creado para que el admin vea el nuevo ticket
        emitTicketCreated({
          id: `ORD-${String(input.ordenId).padStart(6, '0')}`,
          ordenId: input.ordenId,
          total: orden.total,
          status: 'pending',
          createdAt: nowMxISO(),
          cashierName: pago?.empleadoNombre || 'Cajero',
        });
      }
    }
  }

  return pago;
};

export const obtenerFormasPago = () => listarFormasPago();

export const obtenerPropinasServicio = (ordenId?: number) => listarPropinas(ordenId);

export const registrarPropinaServicio = async (
  input: CrearPropinaInput,
  usuarioId?: number
) => {
  const orden = await obtenerOrdenBasePorId(input.ordenId);
  if (!orden) {
    throw notFound('Orden no encontrada');
  }
  const propinaId = await registrarPropina({
    ordenId: input.ordenId,
    monto: input.monto,
    usuarioId: usuarioId ?? null
  });
  const propinas = await listarPropinas(input.ordenId);
  return propinas.find((p) => p.id === propinaId) ?? null;
};

