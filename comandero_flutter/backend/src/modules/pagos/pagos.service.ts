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

  // Si hay múltiples ordenIds (cuenta agrupada), procesar todas las órdenes
  const ordenIdsToProcess = (input.ordenIds && input.ordenIds.length > 1) 
    ? input.ordenIds 
    : [input.ordenId];

  // Calcular totales de todas las órdenes para distribución proporcional del pago
  let totalTodasLasOrdenes = orden.total;
  type OrdenData = { total: number; ordenBase: Awaited<ReturnType<typeof obtenerOrdenBasePorId>> };
  const ordenesData = new Map<number, OrdenData>();
  ordenesData.set(input.ordenId, { total: orden.total, ordenBase: orden });

  if (ordenIdsToProcess.length > 1) {
    // Obtener datos de todas las órdenes
    for (const ordenId of ordenIdsToProcess) {
      if (ordenId !== input.ordenId) {
        const ordenBase = await obtenerOrdenBasePorId(ordenId);
        if (ordenBase) {
          ordenesData.set(ordenId, { total: ordenBase.total, ordenBase });
          totalTodasLasOrdenes += ordenBase.total;
        }
      }
    }
  }

  // Crear pagos para cada orden de la cuenta agrupada
  type PagoCreado = { ordenId: number; monto: number; pago: Awaited<ReturnType<typeof obtenerPago>> };
  const pagosCreados: PagoCreado[] = [];
  const estadoPagada = await obtenerEstadoOrdenPorNombre('pagada');
  
  // Ordenar para procesar la orden principal al final (para usar el monto restante)
  const ordenIdsOrdenados = ordenIdsToProcess.filter(id => id !== input.ordenId).concat([input.ordenId]);
  
  // Para cuentas agrupadas, rastrear todas las órdenes pagadas para emitir un solo ticket
  const ordenesPagadas: Array<{ ordenId: number; total: number }> = [];
  const esCuentaAgrupada = ordenIdsToProcess.length > 1;
  
  for (let i = 0; i < ordenIdsOrdenados.length; i++) {
    const ordenId = ordenIdsOrdenados[i];
    const ordenData = ordenesData.get(ordenId);
    if (!ordenData) continue;

    const esUltima = i === ordenIdsOrdenados.length - 1;
    
    // Calcular monto proporcional para esta orden
    let montoParaEstaOrden: number;
    if (esUltima) {
      // Última orden (principal): usar el monto restante para evitar errores de redondeo
      const montoDistribuido = pagosCreados.reduce((sum, p) => sum + p.monto, 0);
      montoParaEstaOrden = Math.round((input.monto - montoDistribuido) * 100) / 100;
    } else {
      // Órdenes secundarias: monto proporcional al total
      const proporcion = ordenData.total / totalTodasLasOrdenes;
      montoParaEstaOrden = Math.round((input.monto * proporcion) * 100) / 100; // Redondear a 2 decimales
    }

    // Asegurar que el monto no sea negativo ni mayor al total de la orden
    montoParaEstaOrden = Math.max(0, Math.min(montoParaEstaOrden, ordenData.total));

    // Crear pago para esta orden
    const pagoId = await crearPago({
      ordenId: ordenId,
      formaPagoId: input.formaPagoId,
      monto: montoParaEstaOrden,
      referencia: ordenId === input.ordenId ? input.referencia ?? null : `Cuenta agrupada (Orden ${input.ordenId})`,
      estado: input.estado ?? 'aplicado',
      fechaPago: input.fechaPago ?? null,
      empleadoId: usuarioId ?? null
    });

    const pago = await obtenerPago(pagoId);
    pagosCreados.push({ ordenId, monto: montoParaEstaOrden, pago });
    
    // Emitir evento de pago creado
    emitPaymentCreated(pago);
    
    // Si el pago está aplicado, verificar si la orden queda pagada
    if ((input.estado ?? 'aplicado') === 'aplicado') {
      const totalPagado = await obtenerTotalPagado(ordenId);
      if (totalPagado >= ordenData.total && estadoPagada) {
        await actualizarEstadoOrden(ordenId, estadoPagada.id, usuarioId ?? null);
        
        // Obtener orden actualizada para emitir eventos
        const ordenActualizada = await obtenerOrdenDetalle(ordenId);
        
        // Emitir evento de orden actualizada
        await emitOrderUpdated(ordenActualizada, usuarioId, pago?.empleadoNombre || 'Cajero', 'cajero', 'Orden pagada');
        
        // Emitir alerta de pago
        emitPaymentAlert(ordenId, ordenData.total);
        
        // Para cuentas agrupadas, acumular información de órdenes pagadas
        // Solo emitiremos un evento de ticket al final
        if (esCuentaAgrupada) {
          ordenesPagadas.push({ ordenId, total: ordenData.total });
        } else {
          // Para órdenes individuales, emitir evento de ticket inmediatamente
          emitTicketCreated({
            id: `ORD-${String(ordenId).padStart(6, '0')}`,
            ordenId: ordenId,
            total: ordenData.total,
            status: 'pending',
            createdAt: nowMxISO(),
            cashierName: pago?.empleadoNombre || 'Cajero',
          });
        }
      }
    }
  }
  
  // CRÍTICO: Para cuentas agrupadas, emitir UN SOLO evento de ticket con todos los ordenIds
  if (esCuentaAgrupada && ordenesPagadas.length > 0) {
    // Generar un ID único para el ticket agrupado basado en todas las órdenes
    const ordenIdsOrdenadosStr = ordenIdsToProcess.sort((a, b) => a - b).map(id => String(id).padStart(6, '0')).join('-');
    const ticketId = `CUENTA-AGRUPADA-${ordenIdsOrdenadosStr}`;
    const totalAgrupado = ordenesPagadas.reduce((sum, o) => sum + o.total, 0);
    
    emitTicketCreated({
      id: ticketId,
      ordenId: input.ordenId, // Orden principal para compatibilidad
      ordenIds: ordenIdsToProcess, // TODAS las órdenes agrupadas
      total: totalAgrupado,
      status: 'pending',
      createdAt: nowMxISO(),
      cashierName: pagosCreados[0]?.pago?.empleadoNombre || 'Cajero',
      isGrouped: true, // Flag para indicar que es una cuenta agrupada
    });
  }

  // Retornar el pago principal (de la orden principal)
  const pagoPrincipal = pagosCreados.find(p => p.ordenId === input.ordenId);
  return pagoPrincipal ? pagoPrincipal.pago : pagosCreados[0]?.pago;
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

