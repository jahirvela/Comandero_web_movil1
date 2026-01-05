import type { Request, Response, NextFunction } from 'express';
import {
  crearInsumoSchema,
  actualizarInsumoSchema,
  crearMovimientoSchema
} from './inventario.schemas.js';
import {
  obtenerInsumos,
  obtenerInsumo,
  crearNuevoInsumo,
  actualizarInsumoExistente,
  desactivarInsumoExistente,
  registrarMovimientoInventario,
  obtenerMovimientos,
  obtenerCategorias
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
    const itemId = req.query.itemId ? Number(req.query.itemId) : undefined;
    const movimientos = await obtenerMovimientos(itemId);
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

