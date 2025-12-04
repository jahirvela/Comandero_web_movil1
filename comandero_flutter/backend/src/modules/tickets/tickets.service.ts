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

export const imprimirTicket = async (
  input: ImprimirTicketInput,
  usuarioId: number
): Promise<{ exito: boolean; mensaje: string; rutaArchivo?: string }> => {
  try {
    // Obtener datos del ticket
    const datosTicket = await obtenerDatosTicket(input.ordenId, usuarioId);

    if (!datosTicket) {
      throw notFound('Orden no encontrada');
    }

    // Generar contenido del ticket
    const contenido = generarContenidoTicket(datosTicket, input.incluirCodigoBarras ?? true);

    // Crear impresora y enviar
    const printer = createPrinter();
    await printer.print(contenido);
    await printer.close();

    // Registrar en bitácora
    await registrarBitacora(input.ordenId, usuarioId, true, 'Ticket impreso exitosamente');

    logger.info({ ordenId: input.ordenId, usuarioId }, 'Ticket impreso exitosamente');

    const { getEnv } = await import('../../config/env.js');
    const env = getEnv();
    const rutaArchivo =
      env.PRINTER_TYPE === 'simulation' || env.PRINTER_INTERFACE === 'file'
        ? env.PRINTER_DEVICE || env.PRINTER_SIMULATION_PATH
        : undefined;

    // Emitir evento de ticket impreso para que el administrador se entere
    emitTicketPrinted({
      id: `ORD-${String(input.ordenId).padStart(6, '0')}`,
      ordenId: input.ordenId,
      impresoPor: datosTicket.cajero?.nombre || 'Cajero',
      impresoPorId: usuarioId,
      total: datosTicket.orden.total,
      mesaCodigo: datosTicket.orden.mesaCodigo,
      timestamp: nowMxISO(),
    });

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

