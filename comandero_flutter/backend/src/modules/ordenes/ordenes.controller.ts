import type { Request, Response, NextFunction } from 'express';
import {
  crearOrdenSchema,
  actualizarOrdenSchema,
  actualizarEstadoOrdenSchema,
  agregarItemSchema
} from './ordenes.schemas.js';
import {
  obtenerOrdenes,
  obtenerOrdenDetalle,
  crearNuevaOrden,
  actualizarOrdenExistente,
  actualizarEstadoDeOrden,
  actualizarTiempoEstimado,
  agregarItemsOrden,
  obtenerEstadosOrdenServicio
} from './ordenes.service.js';
import { obtenerEstadoOrdenPorNombre } from './ordenes.repository.js';
import { DateTime } from 'luxon';
import { APP_TIMEZONE, nowMx, utcToMx } from '../../config/time.js';

export const listarOrdenesController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const estadoOrdenId = req.query.estadoOrdenId ? Number(req.query.estadoOrdenId) : undefined;
    const mesaId = req.query.mesaId ? Number(req.query.mesaId) : undefined;
    const ordenes = await obtenerOrdenes({ estadoOrdenId, mesaId });
    res.json({ data: ordenes });
  } catch (error) {
    next(error);
  }
};

export const obtenerOrdenController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const orden = await obtenerOrdenDetalle(id);
    res.json({ data: orden });
  } catch (error) {
    next(error);
  }
};

export const crearOrdenController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const input = crearOrdenSchema.parse(req.body);
    const orden = await crearNuevaOrden(input, req.user?.id);
    res.status(201).json({ data: orden });
  } catch (error) {
    next(error);
  }
};

export const actualizarOrdenController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = actualizarOrdenSchema.parse(req.body);
    const orden = await actualizarOrdenExistente(
      id,
      input,
      req.user?.id,
      req.user?.username,
      req.user?.roles[0]
    );
    res.json({ data: orden });
  } catch (error) {
    next(error);
  }
};

export const actualizarEstadoOrdenController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = actualizarEstadoOrdenSchema.parse(req.body);
    
    // Logging detallado para debugging
    console.log('[ORDENES] Cambio de estado solicitado:', {
      ordenId: id,
      nuevoEstadoId: input.estadoOrdenId,
      usuarioId: req.user?.id,
      username: req.user?.username,
      rol: req.user?.roles?.[0],
      tieneUsuario: !!req.user
    });
    
    const orden = await actualizarEstadoDeOrden(
      id,
      input,
      req.user?.id,
      req.user?.username,
      req.user?.roles[0]
    );
    res.json({ data: orden });
  } catch (error) {
    next(error);
  }
};

export const agregarItemsOrdenController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = agregarItemSchema.parse(req.body);
    const orden = await agregarItemsOrden(
      id,
      input,
      req.user?.id,
      req.user?.username,
      req.user?.roles[0]
    );
    res.json({ data: orden });
  } catch (error) {
    next(error);
  }
};

export const listarEstadosOrdenController = async (
  _req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const estados = await obtenerEstadosOrdenServicio();
    res.json({ data: estados });
  } catch (error) {
    next(error);
  }
};

export const actualizarTiempoEstimadoController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const tiempoEstimado = Number(req.body.tiempoEstimado);
    
    if (!tiempoEstimado || tiempoEstimado < 1 || tiempoEstimado > 120) {
      return res.status(400).json({ 
        error: 'El tiempo estimado debe estar entre 1 y 120 minutos' 
      });
    }
    
    const orden = await actualizarTiempoEstimado(
      id,
      tiempoEstimado,
      req.user?.id,
      req.user?.username,
      req.user?.roles[0]
    );
    res.json({ data: orden });
  } catch (error) {
    next(error);
  }
};

export const listarOrdenesCocinaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    // Obtener todos los estados de orden
    const { listarEstadosOrden } = await import('./ordenes.repository.js');
    const estados = await listarEstadosOrden();
    
    // Identificar estados relevantes para cocina (no pagadas, no canceladas, no cerradas, NO LISTAS)
    // Las órdenes "listas" ya fueron completadas y no deben aparecer en cocina
    const estadosExcluidos = ['pagada', 'cancelada', 'cerrada', 'listo', 'ready', 'completada', 'finalizada'];
    const estadosCocina = estados
      .filter((estado) => {
        const nombreLower = estado.nombre.toLowerCase();
        // Excluir estados que contengan alguna de las palabras excluidas
        const debeExcluir = estadosExcluidos.some((excluido) => 
          nombreLower.includes(excluido.toLowerCase())
        );
        if (debeExcluir) {
          console.log(`Estado excluido de cocina: ${estado.nombre} (ID: ${estado.id})`);
        }
        return !debeExcluir;
      })
      .map((estado) => estado.id);
    
    console.log(`Estados permitidos para cocina: ${estadosCocina.join(', ')}`);
    
    // Obtener todas las órdenes y filtrar por estados de cocina
    const todasLasOrdenes = await obtenerOrdenes({});
    
    // Filtrar órdenes que estén en estados relevantes para cocina
    // ADICIONALMENTE: Filtrar por nombre de estado.
    // Nota: no filtramos por fecha porque el desfase de zona horaria
    // puede ocultar órdenes recién creadas.
    
    const ordenesCocina = todasLasOrdenes.filter((orden) => {
      const estadoNombreLower = (orden.estadoNombre || '').toLowerCase();
      const esEstadoListo = estadoNombreLower.includes('listo') || 
                           estadoNombreLower.includes('ready') ||
                           estadoNombreLower.includes('completada') ||
                           estadoNombreLower.includes('finalizada') ||
                           estadoNombreLower.includes('pagada') ||
                           estadoNombreLower.includes('cancelada');
      
      // Debe estar en estados permitidos Y no tener nombre de estado "listo"
      const incluir = estadosCocina.includes(orden.estadoOrdenId) && !esEstadoListo;
      
      if (!incluir) {
        console.log(`Orden ${orden.id} excluida - Estado: "${orden.estadoNombre}" (ID: ${orden.estadoOrdenId})`);
      }
      
      return incluir;
    });
    
    console.log(`Total órdenes: ${todasLasOrdenes.length}, Órdenes para cocina: ${ordenesCocina.length}`);
    
    // Obtener detalles completos de cada orden (con items) para cocina
    const { obtenerOrdenDetalle } = await import('./ordenes.service.js');
    const ordenesConDetalle = await Promise.all(
      ordenesCocina.map(async (orden) => {
        try {
          return await obtenerOrdenDetalle(orden.id);
        } catch (error) {
          // Si falla obtener el detalle, devolver la orden básica
          return orden;
        }
      })
    );
    
    res.json({ data: ordenesConDetalle });
  } catch (error) {
    next(error);
  }
};

