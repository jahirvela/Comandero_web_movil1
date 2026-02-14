import type { Request, Response, NextFunction } from 'express';
import {
  crearProductoSchema,
  actualizarProductoSchema
} from './productos.schemas.js';
import {
  obtenerProductos,
  obtenerProducto,
  crearNuevoProducto,
  actualizarProductoExistente,
  desactivarProductoExistente
} from './productos.service.js';
import { emitProductUpdated } from '../../realtime/events.js';

export const listarProductosController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const categoriaId = req.query.categoriaId ? Number(req.query.categoriaId) : undefined;
    const productos = await obtenerProductos(categoriaId);
    res.json({ data: productos });
  } catch (error) {
    next(error);
  }
};

export const obtenerProductoController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const producto = await obtenerProducto(id);
    res.json({ data: producto });
  } catch (error) {
    next(error);
  }
};

export const crearProductoController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const input = crearProductoSchema.parse(req.body);
    const producto = await crearNuevoProducto(input);
    emitProductUpdated(producto);
    res.status(201).json({ data: producto });
  } catch (error) {
    next(error);
  }
};

export const actualizarProductoController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = actualizarProductoSchema.parse(req.body);
    const producto = await actualizarProductoExistente(id, input);
    emitProductUpdated(producto);
    res.json({ data: producto });
  } catch (error) {
    next(error);
  }
};

export const desactivarProductoController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    await desactivarProductoExistente(id);
    emitProductUpdated({ id });
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

