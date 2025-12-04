import {
  listarRoles,
  obtenerRolPorId,
  crearRol,
  actualizarRol,
  eliminarRol,
  listarPermisos
} from './roles.repository.js';
import type { ActualizarRolInput, CrearRolInput } from './roles.schemas.js';
import { badRequest, notFound } from '../../utils/http-error.js';

export const obtenerRoles = () => listarRoles();

export const obtenerRol = async (id: number) => {
  const rol = await obtenerRolPorId(id);
  if (!rol) {
    throw notFound('Rol no encontrado');
  }
  return rol;
};

const validarPermisos = async (permisosSolicitados: number[]) => {
  if (!permisosSolicitados || permisosSolicitados.length === 0) return;

  const permisosDisponibles = await listarPermisos();
  const validos = new Set(permisosDisponibles.map((permiso) => permiso.id));
  const invalidos = permisosSolicitados.filter((permisoId) => !validos.has(permisoId));
  if (invalidos.length > 0) {
    throw badRequest(`Permisos inválidos: ${invalidos.join(', ')}`);
  }
};

export const crearNuevoRol = async (input: CrearRolInput) => {
  await validarPermisos(input.permisos ?? []);
  const rolId = await crearRol({
    nombre: input.nombre,
    descripcion: input.descripcion ?? null,
    permisos: input.permisos ?? []
  });
  return obtenerRol(rolId);
};

export const actualizarRolExistente = async (id: number, input: ActualizarRolInput) => {
  const existe = await obtenerRolPorId(id);
  if (!existe) {
    throw notFound('Rol no encontrado');
  }

  if (input.permisos) {
    await validarPermisos(input.permisos);
  }

  await actualizarRol(id, {
    nombre: input.nombre,
    descripcion: input.descripcion ?? null,
    permisos: input.permisos
  });

  return obtenerRol(id);
};

export const eliminarRolExistente = async (id: number) => {
  const existe = await obtenerRolPorId(id);
  if (!existe) {
    throw notFound('Rol no encontrado');
  }
  await eliminarRol(id);
};

export const obtenerPermisos = () => listarPermisos();

