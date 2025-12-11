import { obtenerDatosTicket, listarTickets } from './tickets.repository.js';
import { createPrinter, generarContenidoTicket } from './tickets.printer.js';
import { logger } from '../../config/logger.js';
import { notFound } from '../../utils/http-error.js';
import type { ImprimirTicketInput } from './tickets.schemas.js';
import { pool } from '../../db/pool.js';
import { emitTicketPrinted } from '../../realtime/events.js';
import { nowMxISO } from '../../config/time.js';

interface BitacoraImpresionRow {
  id?: number;
  orden_id: number;
  usuario_id: number | null;
  exito: boolean;
  mensaje: string | null;
  creado_en: Date;
}

/**
 * Registra una impresión en la bitácora (opcional)
 */
const registrarBitacora = async (
  ordenId: number,
  usuarioId: number | null,
  exito: boolean,
  mensaje: string | null = null
): Promise<void> => {
  try {
    // Verificar si existe la tabla bitacora_impresion
    // Si no existe, solo logueamos (no falla)
    await pool.query(
      `INSERT INTO bitacora_impresion (orden_id, usuario_id, exito, mensaje, creado_en)
       VALUES (?, ?, ?, ?, NOW())`,
      [ordenId, usuarioId, exito ? 1 : 0, mensaje]
    );
  } catch (error: any) {
    // Si la tabla no existe, solo logueamos el error pero no fallamos
    if (error.code === 'ER_NO_SUCH_TABLE') {
      logger.debug('Tabla bitacora_impresion no existe, omitiendo registro');
    } else {
      logger.warn({ err: error }, 'Error al registrar en bitácora de impresión');
    }
  }
};

/**
 * Registra múltiples impresiones en la bitácora (para cuentas agrupadas)
 */
const registrarBitacoraMultiples = async (
  ordenIds: number[],
  usuarioId: number | null,
  exito: boolean,
  mensaje: string | null = null
): Promise<void> => {
  if (ordenIds.length === 0) return;
  
  try {
    // Crear array de valores para INSERT múltiple
    const values = ordenIds.map(() => '(?, ?, ?, ?, NOW())').join(', ');
    const params: any[] = [];
    
    for (const ordenId of ordenIds) {
      params.push(ordenId, usuarioId, exito ? 1 : 0, mensaje);
    }
    
    await pool.query(
      `INSERT INTO bitacora_impresion (orden_id, usuario_id, exito, mensaje, creado_en)
       VALUES ${values}`,
      params
    );
    
    logger.info({ ordenIds, usuarioId, count: ordenIds.length }, 'Registradas múltiples impresiones en bitácora');
  } catch (error: any) {
    // Si la tabla no existe, solo logueamos el error pero no fallamos
    if (error.code === 'ER_NO_SUCH_TABLE') {
      logger.debug('Tabla bitacora_impresion no existe, omitiendo registro');
    } else {
      logger.warn({ err: error }, 'Error al registrar múltiples impresiones en bitácora');
      // Intentar registrar una por una como fallback
      for (const ordenId of ordenIds) {
        await registrarBitacora(ordenId, usuarioId, exito, mensaje);
      }
    }
  }
};

export const imprimirTicket = async (
  input: ImprimirTicketInput,
  usuarioId: number
): Promise<{ exito: boolean; mensaje: string; rutaArchivo?: string }> => {
  try {
    // Obtener datos del ticket - si hay múltiples ordenIds, obtener datos de todas las órdenes
    const ordenIds = (input.ordenIds && input.ordenIds.length > 1) ? input.ordenIds : undefined;
    const datosTicket = await obtenerDatosTicket(input.ordenId, usuarioId, ordenIds);

    if (!datosTicket) {
      throw notFound('Orden no encontrada');
    }

    // Generar contenido del ticket
    const contenido = generarContenidoTicket(datosTicket, input.incluirCodigoBarras ?? true);

    // Crear impresora y enviar
    const printer = createPrinter();
    await printer.print(contenido);
    await printer.close();

    // Registrar en bitácora - si hay múltiples ordenIds (cuenta agrupada), registrar todos
    if (input.ordenIds && input.ordenIds.length > 1) {
      await registrarBitacoraMultiples(
        input.ordenIds,
        usuarioId,
        true,
        `Ticket agrupado impreso exitosamente (${input.ordenIds.length} órdenes)`
      );
      logger.info({ ordenIds: input.ordenIds, usuarioId, count: input.ordenIds.length }, 'Ticket agrupado impreso exitosamente');
    } else {
      // Registrar solo la orden principal (o todas si son múltiples pero se pasaron como array)
      const ordenIdsToRegister = input.ordenIds && input.ordenIds.length > 0 
        ? input.ordenIds 
        : [input.ordenId];
      
      if (ordenIdsToRegister.length === 1) {
        await registrarBitacora(ordenIdsToRegister[0], usuarioId, true, 'Ticket impreso exitosamente');
        logger.info({ ordenId: ordenIdsToRegister[0], usuarioId }, 'Ticket impreso exitosamente');
      } else {
        await registrarBitacoraMultiples(ordenIdsToRegister, usuarioId, true, 'Ticket impreso exitosamente');
        logger.info({ ordenIds: ordenIdsToRegister, usuarioId, count: ordenIdsToRegister.length }, 'Ticket impreso exitosamente');
      }
    }

    const { getEnv } = await import('../../config/env.js');
    const env = getEnv();
    const rutaArchivo =
      env.PRINTER_TYPE === 'simulation' || env.PRINTER_INTERFACE === 'file'
        ? env.PRINTER_DEVICE || env.PRINTER_SIMULATION_PATH
        : undefined;

    // Emitir evento de ticket impreso para que el administrador se entere
    // Si hay múltiples ordenIds, emitir evento para cada uno
    const ordenIdsToEmit = input.ordenIds && input.ordenIds.length > 1 
      ? input.ordenIds 
      : [input.ordenId];
    
    for (const ordenIdEmit of ordenIdsToEmit) {
      emitTicketPrinted({
        id: `ORD-${String(ordenIdEmit).padStart(6, '0')}`,
        ordenId: ordenIdEmit,
        impresoPor: datosTicket.cajero?.nombre || 'Cajero',
        impresoPorId: usuarioId,
        total: datosTicket.orden.total,
        mesaCodigo: datosTicket.orden.mesaCodigo,
        timestamp: nowMxISO(),
      });
    }

    return {
      exito: true,
      mensaje: 'Ticket impreso exitosamente',
      rutaArchivo
    };
  } catch (error: any) {
    logger.error({ err: error, ordenId: input.ordenId, usuarioId }, 'Error al imprimir ticket');

    // Registrar error en bitácora
    await registrarBitacora(
      input.ordenId,
      usuarioId,
      false,
      error.message || 'Error desconocido al imprimir'
    );

    // No lanzar el error, devolver respuesta amigable
    return {
      exito: false,
      mensaje: error.message || 'No se pudo imprimir el ticket. Verifica que la impresora esté conectada.'
    };
  }
};

export const obtenerListaTickets = async () => {
  try {
    const tickets = await listarTickets();
    return tickets;
  } catch (error: any) {
    logger.error({ err: error }, 'Error al listar tickets');
    throw error;
  }
};

