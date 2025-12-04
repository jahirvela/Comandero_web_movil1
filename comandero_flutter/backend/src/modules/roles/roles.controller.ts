import type { Request, Response, NextFunction } from 'express';
import { crearRolSchema, actualizarRolSchema } from './roles.schemas.js';
import {
  obtenerRoles,
  obtenerRol,
  crearNuevoRol,
  actualizarRolExistente,
  eliminarRolExistente,
  obtenerPermisos
} from './roles.service.js';

export const listarRolesController = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const roles = await obtenerRoles();
    res.json({ data: roles });
  } catch (error) {
    next(error);
  }
};

export const obtenerRolController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const rol = await obtenerRol(id);
    res.json({ data: rol });
  } catch (error) {
    next(error);
  }
};

export const crearRolController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const input = crearRolSchema.parse(req.body);
    const rol = await crearNuevoRol(input);
    res.status(201).json({ data: rol });
  } catch (error) {
    next(error);
  }
};

export const actualizarRolController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const input = actualizarRolSchema.parse(req.body);
    const rol = await actualizarRolExistente(id, input);
    res.json({ data: rol });
  } catch (error) {
    next(error);
  }
};

export const eliminarRolController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    await eliminarRolExistente(id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

export const listarPermisosController = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const permisos = await obtenerPermisos();
    res.json({ data: permisos });
  } catch (error) {
    next(error);
  }
};

