import type { Request, Response, NextFunction } from 'express';
import {
  crearCategoriaSchema,
  actualizarCategoriaSchema
} from './categorias.schemas.js';
import {
  obtenerCategorias,
  obtenerCategoria,
  crearNuevaCategoria,
  actualizarCategoriaExistente,
  eliminarCategoriaExistente
} from './categorias.service.js';

export const listarCategoriasController = async (
  _req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const categorias = await obtenerCategorias();
    res.json({ data: categorias });
  } catch (error) {
    next(error);
  }
};

export const obtenerCategoriaController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const categoria = await obtenerCategoria(id);
    res.json({ data: categoria });
  } catch (error) {
    next(error);
  }
};

export const crearCategoriaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const input = crearCategoriaSchema.parse(req.body);
    const categoria = await crearNuevaCategoria(input);
    res.status(201).json({ data: categoria });
  } catch (error) {
    next(error);
  }
};

export const actualizarCategoriaController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = actualizarCategoriaSchema.parse(req.body);
    const categoria = await actualizarCategoriaExistente(id, input);
    res.json({ data: categoria });
  } catch (error) {
    next(error);
  }
};

export const eliminarCategoriaController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    await eliminarCategoriaExistente(id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

