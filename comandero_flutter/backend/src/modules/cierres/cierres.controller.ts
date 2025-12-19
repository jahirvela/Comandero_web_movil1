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

    // Obtener el rol del usuario (puede ser array o string)
    const userRoles = req.user?.roles;
    const usuarioRol = Array.isArray(userRoles) && userRoles.length > 0 
      ? String(userRoles[0]).toLowerCase() 
      : null;
    const usuarioNombre = req.user?.nombre || req.user?.username || 'Usuario';

    // Si el usuario es cajero, solo puede descartar aclaraciones (clarification -> approved)
    if (usuarioRol === 'cajero') {
      // Obtener el estado actual del cierre
      const { obtenerCierreCajaPorId } = await import('./cierres.repository.js');
      const cierreActual = await obtenerCierreCajaPorId(cierreId);
      
      if (!cierreActual) {
        throw notFound('Cierre de caja no encontrado');
      }

      // Verificar que el estado actual sea "clarification" y el nuevo estado sea "approved"
      if (cierreActual.status !== 'clarification') {
        throw badRequest('Solo puedes descartar aclaraciones pendientes');
      }

      if (parsed.data.estado !== 'approved') {
        throw badRequest('Como cajero, solo puedes aprobar aclaraciones para descartarlas');
      }

      // Verificar que el cajero sea el dueño del cierre
      if (cierreActual.cajeroId !== usuarioId) {
        throw badRequest('Solo puedes descartar tus propias aclaraciones');
      }
    }

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

