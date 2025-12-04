import type { Request, Response, NextFunction } from 'express';
import {
  crearReservaSchema,
  actualizarReservaSchema,
  listarReservasSchema,
} from './reservas.schemas.js';
import {
  obtenerReservas,
  obtenerReserva,
  crearNuevaReserva,
  actualizarReservaExistente,
  eliminarReservaExistente,
} from './reservas.service.js';
import { badRequest } from '../../utils/http-error.js';

export const listarReservasController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const parsed = listarReservasSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const reservas = await obtenerReservas(parsed.data);
    res.json({ data: reservas });
  } catch (error) {
    next(error);
  }
};

export const obtenerReservaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const reserva = await obtenerReserva(id);
    res.json({ data: reserva });
  } catch (error) {
    next(error);
  }
};

export const crearReservaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const parsed = crearReservaSchema.safeParse(req.body);
    if (!parsed.success) {
      throw badRequest('Datos inválidos', parsed.error.flatten().fieldErrors);
    }

    const usuarioId = req.user?.id;
    const reserva = await crearNuevaReserva(parsed.data, usuarioId);
    res.status(201).json({ data: reserva });
  } catch (error) {
    next(error);
  }
};

export const actualizarReservaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const parsed = actualizarReservaSchema.safeParse(req.body);
    if (!parsed.success) {
      throw badRequest('Datos inválidos', parsed.error.flatten().fieldErrors);
    }

    const usuarioId = req.user?.id;
    const reserva = await actualizarReservaExistente(id, parsed.data, usuarioId);
    res.json({ data: reserva });
  } catch (error) {
    next(error);
  }
};

export const eliminarReservaController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    await eliminarReservaExistente(id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

