import type { Request, Response, NextFunction } from 'express';
import { obtenerCierresCaja, crearNuevoCierreCaja, actualizarEstadoCierre } from './cierres.service.js';
import { listarCierresCajaSchema, crearCierreCajaSchema, actualizarEstadoCierreSchema } from './cierres.schemas.js';
import { badRequest, notFound } from '../../utils/http-error.js';
import { emitCashClosureCreated, emitCashClosureUpdated } from '../../realtime/events.js';

export const listarCierresCajaHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = listarCierresCajaSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const { fechaInicio, fechaFin, cajeroId } = parsed.data;
    
    // Si el usuario es cajero, solo puede ver sus propios cierres
    const usuarioId = req.user?.id;
    const usuarioRol = req.user?.rol;
    const cajeroIdFiltro = usuarioRol === 'cajero' ? usuarioId : cajeroId;

    const cierres = await obtenerCierresCaja(fechaInicio, fechaFin, cajeroIdFiltro);

    console.log(`📤 CierresController: Enviando ${cierres.length} cierres al frontend`);
    if (cierres.length > 0) {
      console.log(`📤 CierresController: Primer cierre:`, JSON.stringify(cierres[0], null, 2));
    }

    res.status(200).json({
      success: true,
      data: cierres
    });
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al obtener cierres de caja'
    });
  }
};

export const crearCierreCajaHandler = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const parsed = crearCierreCajaSchema.safeParse(req.body);
    if (!parsed.success) {
      throw badRequest('Datos inválidos', parsed.error.flatten().fieldErrors);
    }

    const usuarioId = req.user?.id;
    const usuarioNombre = req.user?.nombre || req.user?.username || 'Cajero';
    const cierre = await crearNuevoCierreCaja(parsed.data, usuarioId);

    // Emitir evento de Socket.IO para notificar a administradores y otros clientes
    // IMPORTANTE: Emitir tanto created como updated para asegurar que todos los clientes se actualicen
    emitCashClosureCreated({
      ...cierre,
      usuario: usuarioNombre,
      creadoPorNombre: usuarioNombre,
    });
    
    // También emitir updated por si fue una actualización de un cierre existente
    emitCashClosureUpdated({
      ...cierre,
      usuario: usuarioNombre,
      creadoPorNombre: usuarioNombre,
    });

    res.status(201).json({
      success: true,
      data: cierre
    });
  } catch (error: any) {
    next(error);
  }
};

export const actualizarEstadoCierreHandler = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const cierreId = parseInt(req.params.id, 10);
    if (isNaN(cierreId)) {
      throw badRequest('ID de cierre inválido');
    }

    const parsed = actualizarEstadoCierreSchema.safeParse(req.body);
    if (!parsed.success) {
      throw badRequest('Datos inválidos', parsed.error.flatten().fieldErrors);
    }

    const usuarioId = req.user?.id;
    if (!usuarioId) {
      throw badRequest('Usuario no autenticado');
    }

    const usuarioNombre = req.user?.nombre || req.user?.username || 'Administrador';

    const cierreActualizado = await actualizarEstadoCierre(
      cierreId,
      parsed.data.estado,
      usuarioId,
      parsed.data.comentarioRevision
    );

    if (!cierreActualizado) {
      throw notFound('Cierre de caja no encontrado');
    }

    // Emitir evento de Socket.IO para notificar al cajero y otros clientes
    emitCashClosureUpdated({
      ...cierreActualizado,
      revisadoPorNombre: usuarioNombre,
      comentarioRevision: parsed.data.comentarioRevision,
    });

    res.status(200).json({
      success: true,
      data: cierreActualizado
    });
  } catch (error: any) {
    next(error);
  }
};

