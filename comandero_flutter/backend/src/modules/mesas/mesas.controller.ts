import type { Request, Response, NextFunction } from 'express';
import {
  crearMesaSchema,
  actualizarMesaSchema,
  cambiarEstadoMesaSchema
} from './mesas.schemas.js';
import {
  obtenerMesas,
  obtenerMesa,
  crearNuevaMesa,
  actualizarMesaExistente,
  desactivarMesa,
  cambiarEstadoDeMesa,
  obtenerHistorialDeMesa,
  obtenerEstadosMesa
} from './mesas.service.js';

export const listarMesasController = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const mesas = await obtenerMesas();
    res.json({ data: mesas });
  } catch (error) {
    next(error);
  }
};

export const obtenerMesaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const mesa = await obtenerMesa(id);
    res.json({ data: mesa });
  } catch (error) {
    next(error);
  }
};

export const crearMesaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const input = crearMesaSchema.parse(req.body);
    const mesa = await crearNuevaMesa(input);
    res.status(201).json({ data: mesa });
  } catch (error) {
    next(error);
  }
};

export const actualizarMesaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const input = actualizarMesaSchema.parse(req.body);
    const mesa = await actualizarMesaExistente(id, input);
    res.json({ data: mesa });
  } catch (error) {
    next(error);
  }
};

export const eliminarMesaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    await desactivarMesa(id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

export const cambiarEstadoMesaController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = cambiarEstadoMesaSchema.parse(req.body);
    const mesa = await cambiarEstadoDeMesa(id, input, req.user?.id);
    res.json({ data: mesa });
  } catch (error) {
    next(error);
  }
};

export const historialMesaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const historial = await obtenerHistorialDeMesa(id);
    res.json({ data: historial });
  } catch (error) {
    next(error);
  }
};

export const estadosMesaController = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const estados = await obtenerEstadosMesa();
    res.json({ data: estados });
  } catch (error) {
    next(error);
  }
};

