import type { Request, Response, NextFunction } from 'express';
import {
  crearInsumoSchema,
  actualizarInsumoSchema,
  crearMovimientoSchema,
  crearCategoriaInventarioSchema,
  renombrarCategoriaInventarioSchema
} from './inventario.schemas.js';
import {
  obtenerInsumos,
  obtenerInsumo,
  obtenerInsumoPorCodigoBarrasService,
  crearNuevoInsumo,
  actualizarInsumoExistente,
  desactivarInsumoExistente,
  registrarMovimientoInventario,
  obtenerMovimientos,
  obtenerCategorias,
  crearCategoriaInventario,
  eliminarCategoriaInventario,
  renombrarCategoriaInventario
} from './inventario.service.js';
import {
  emitInventoryCreated,
  emitInventoryUpdated,
  emitInventoryDeleted
} from '../../realtime/events.js';

export const listarInsumosController = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const insumos = await obtenerInsumos();
    res.json({ data: insumos });
  } catch (error) {
    next(error);
  }
};

export const obtenerInsumoController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const insumo = await obtenerInsumo(id);
    res.json({ data: insumo });
  } catch (error) {
    next(error);
  }
};

export const obtenerInsumoPorCodigoBarrasController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const codigo = String(req.query.codigo ?? req.query.codigoBarras ?? '').trim();
    if (!codigo) {
      return res.status(400).json({ error: 'codigo_requerido', message: 'Query "codigo" o "codigoBarras" es requerido' });
    }
    const insumo = await obtenerInsumoPorCodigoBarrasService(codigo);
    if (!insumo) {
      return res.status(404).json({ error: 'no_encontrado', message: 'No hay ningún ítem de inventario con ese código de barras' });
    }
    res.json({ data: insumo });
  } catch (error) {
    next(error);
  }
};

export const crearInsumoController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const input = crearInsumoSchema.parse(req.body);
    const insumo = await crearNuevoInsumo(input);
    // Emitir evento de socket
    emitInventoryCreated(insumo);
    res.status(201).json({ data: insumo });
  } catch (error) {
    next(error);
  }
};

export const actualizarInsumoController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = actualizarInsumoSchema.parse(req.body);
    const insumo = await actualizarInsumoExistente(id, input);
    // Emitir evento de socket
    emitInventoryUpdated(insumo);
    res.json({ data: insumo });
  } catch (error) {
    next(error);
  }
};

export const eliminarInsumoController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    await desactivarInsumoExistente(id);
    // Emitir evento de socket
    emitInventoryDeleted(id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

export const registrarMovimientoController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const input = crearMovimientoSchema.parse(req.body);
    const insumo = await registrarMovimientoInventario(input, req.user?.id);
    // Emitir evento de socket para actualizar inventario en tiempo real
    emitInventoryUpdated(insumo);
    res.status(201).json({ data: insumo });
  } catch (error) {
    next(error);
  }
};

export const listarMovimientosController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const itemIdRaw = req.query.itemId ? Number(req.query.itemId) : undefined;
    const limitRaw = req.query.limit != null ? Number(req.query.limit) : undefined;
    let desde: Date | undefined;
    let hasta: Date | undefined;
    if (req.query.desde) {
      const d = new Date(String(req.query.desde));
      if (!Number.isNaN(d.getTime())) desde = d;
    }
    if (req.query.hasta) {
      const d = new Date(String(req.query.hasta));
      if (!Number.isNaN(d.getTime())) hasta = d;
    }
    const movimientos = await obtenerMovimientos({
      inventarioItemId: itemIdRaw != null && Number.isFinite(itemIdRaw) ? itemIdRaw : undefined,
      desde,
      hasta,
      limit: limitRaw != null && Number.isFinite(limitRaw) ? limitRaw : undefined
    });
    res.json({ data: movimientos });
  } catch (error) {
    next(error);
  }
};

export const listarCategoriasController = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const categorias = await obtenerCategorias();
    res.json({ data: categorias });
  } catch (error) {
    next(error);
  }
};

export const crearCategoriaInventarioController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const parsed = crearCategoriaInventarioSchema.safeParse(req.body);
    if (!parsed.success) {
      const msg = parsed.error.errors.map(e => e.message).join('; ') || 'Nombre de categoría inválido';
      res.status(400).json({ message: msg });
      return;
    }
    const { categorias, created } = await crearCategoriaInventario(parsed.data.nombre);
    if (!created) {
      res.status(409).json({
        message: 'Ya existe una categoría con ese nombre (se compara sin importar mayúsculas)',
        data: categorias
      });
      return;
    }
    res.status(201).json({ data: categorias });
  } catch (error) {
    next(error);
  }
};

export const eliminarCategoriaInventarioController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const nombre = decodeURIComponent(String(req.params.nombre ?? '')).trim();
    if (!nombre) {
      res.status(400).json({ message: 'Nombre de categoría inválido' });
      return;
    }
    const categorias = await eliminarCategoriaInventario(nombre);
    res.json({ data: categorias });
  } catch (error) {
    next(error);
  }
};

export const renombrarCategoriaInventarioController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const nombre = decodeURIComponent(String(req.params.nombre ?? '')).trim();
    if (!nombre) {
      res.status(400).json({ message: 'Nombre de categoría inválido' });
      return;
    }
    const parsed = renombrarCategoriaInventarioSchema.safeParse(req.body);
    if (!parsed.success) {
      const msg = parsed.error.errors.map((e) => e.message).join('; ') || 'Datos inválidos';
      res.status(400).json({ message: msg });
      return;
    }
    const categorias = await renombrarCategoriaInventario(nombre, parsed.data.nuevoNombre);
    res.json({ data: categorias });
  } catch (error) {
    next(error);
  }
};

