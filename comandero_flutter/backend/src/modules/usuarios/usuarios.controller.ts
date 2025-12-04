import type { Request, Response, NextFunction } from 'express';
import {
  crearUsuarioSchema,
  actualizarUsuarioSchema,
  asignarRolesSchema
} from './usuarios.schemas.js';
import {
  obtenerUsuarios,
  obtenerUsuario,
  crearNuevoUsuario,
  actualizarUsuarioExistente,
  eliminarUsuarioExistente,
  asignarRoles,
  obtenerCatalogoRoles
} from './usuarios.service.js';

export const listarUsuariosController = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const usuarios = await obtenerUsuarios();
    res.json({ data: usuarios });
  } catch (error) {
    next(error);
  }
};

export const obtenerUsuarioController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const usuario = await obtenerUsuario(id);
    res.json({ data: usuario });
  } catch (error) {
    next(error);
  }
};

export const crearUsuarioController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const input = crearUsuarioSchema.parse(req.body);
    const nuevoUsuario = await crearNuevoUsuario(input, req.user?.id);
    res.status(201).json({ data: nuevoUsuario });
  } catch (error) {
    next(error);
  }
};

export const actualizarUsuarioController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = actualizarUsuarioSchema.parse(req.body);
    const usuarioActualizado = await actualizarUsuarioExistente(id, input, req.user?.id);
    res.json({ data: usuarioActualizado });
  } catch (error) {
    next(error);
  }
};

export const eliminarUsuarioController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    await eliminarUsuarioExistente(id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

export const asignarRolesUsuarioController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const id = Number(req.params.id);
    const input = asignarRolesSchema.parse(req.body);
    const usuario = await asignarRoles(id, input);
    res.json({ data: usuario });
  } catch (error) {
    next(error);
  }
};

export const listarRolesController = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const roles = await obtenerCatalogoRoles();
    res.json({ data: roles });
  } catch (error) {
    next(error);
  }
};

