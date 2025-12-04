import type { Request, Response } from 'express';
import { imprimirTicket, obtenerListaTickets } from './tickets.service.js';
import { imprimirTicketSchema } from './tickets.schemas.js';
import { badRequest } from '../../utils/http-error.js';
import { emitTicketPrinted, emitTicketCreated } from '../../realtime/events.js';
import { nowMxISO } from '../../config/time.js';

export const imprimirTicketHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = imprimirTicketSchema.safeParse(req.body);
    if (!parsed.success) {
      throw badRequest('Datos inválidos', parsed.error.flatten().fieldErrors);
    }

    const usuarioId = req.user?.id;
    const usuarioNombre = req.user?.nombre || req.user?.username || 'Cajero';
    if (!usuarioId) {
      throw badRequest('Usuario no autenticado');
    }

    const resultado = await imprimirTicket(parsed.data, usuarioId);

    if (resultado.exito) {
      // Emitir evento de Socket.IO para notificar a administradores y otros clientes
      emitTicketPrinted({
        ordenId: parsed.data.ordenId,
        impresoPor: usuarioNombre,
        impresoPorId: usuarioId,
        fechaImpresion: nowMxISO(),
        rutaArchivo: resultado.rutaArchivo,
      });

      res.status(200).json({
        success: true,
        data: {
          mensaje: resultado.mensaje,
          rutaArchivo: resultado.rutaArchivo
        }
      });
    } else {
      res.status(500).json({
        success: false,
        error: resultado.mensaje
      });
    }
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al imprimir ticket'
    });
  }
};

export const listarTicketsHandler = async (_req: Request, res: Response): Promise<void> => {
  try {
    const tickets = await obtenerListaTickets();
    res.status(200).json({
      success: true,
      data: tickets
    });
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al obtener tickets'
    });
  }
};

