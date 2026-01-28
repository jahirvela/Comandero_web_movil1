import { hashPassword } from '../../utils/password.js';
import {
  actualizarUsuario,
  crearUsuario,
  eliminarUsuario,
  eliminarUsuarioPermanente,
  listarUsuarios,
  obtenerRolesDisponibles,
  obtenerUsuarioPorId
} from './usuarios.repository.js';
import type {
  ActualizarUsuarioInput,
  AsignarRolesInput,
  CrearUsuarioInput
} from './usuarios.schemas.js';
import { badRequest, notFound } from '../../utils/http-error.js';

export const obtenerUsuarios = () => listarUsuarios();

export const obtenerUsuario = async (id: number) => {
  const usuario = await obtenerUsuarioPorId(id);
  if (!usuario) {
    throw notFound('Usuario no encontrado');
  }
  return usuario;
};

export const crearNuevoUsuario = async (input: CrearUsuarioInput, actorId: number | undefined) => {
  const { password, roles, ...rest } = input;

  if (roles && roles.length > 0) {
    const rolesDisponibles = await obtenerRolesDisponibles();
    const rolesValidos = new Set(rolesDisponibles.map((rol) => rol.id));
    const invalidos = roles.filter((rolId) => !rolesValidos.has(rolId));
    if (invalidos.length > 0) {
      throw badRequest(`Roles inválidos: ${invalidos.join(', ')}`);
    }
  }

  const passwordHash = await hashPassword(password);
  const usuarioId = await crearUsuario({
    ...rest,
    passwordHash,
    passwordPlain: password, // Guardar contraseña en texto plano para visualización del administrador
    roles: roles ?? [],
    activo: rest.activo ?? true,
    actualizadoPor: actorId
  });

  const usuario = await obtenerUsuario(usuarioId);
  // La contraseña ya está incluida en el usuario desde el repositorio
  return usuario;
};

export const actualizarUsuarioExistente = async (
  id: number,
  input: ActualizarUsuarioInput,
  actorId: number | undefined
) => {
  const existe = await obtenerUsuarioPorId(id);
  if (!existe) {
    throw notFound('Usuario no encontrado');
  }

  let passwordHash: string | undefined;
  let passwordPlain: string | undefined;
  if (input.password) {
    passwordHash = await hashPassword(input.password);
    passwordPlain = input.password; // Guardar contraseña en texto plano
  }

  await actualizarUsuario(id, {
    nombre: input.nombre,
    telefono: input.telefono,
    activo: input.activo,
    passwordHash,
    passwordPlain, // Guardar contraseña en texto plano para visualización del administrador
    roles: input.roles,
    actualizadoPor: actorId
  });

  const usuario = await obtenerUsuario(id);
  // La contraseña ya está incluida en el usuario desde el repositorio
  return usuario;
};

export const eliminarUsuarioExistente = async (id: number) => {
  const existe = await obtenerUsuarioPorId(id);
  if (!existe) {
    throw notFound('Usuario no encontrado');
  }
  await eliminarUsuario(id);
};

export const eliminarUsuarioPermanenteExistente = async (id: number) => {
  const existe = await obtenerUsuarioPorId(id);
  if (!existe) {
    throw notFound('Usuario no encontrado');
  }
  await eliminarUsuarioPermanente(id);
};

export const asignarRoles = async (id: number, input: AsignarRolesInput) => {
  const usuario = await obtenerUsuarioPorId(id);
  if (!usuario) {
    throw notFound('Usuario no encontrado');
  }
  await actualizarUsuario(id, {
    roles: input.roles,
    actualizadoPor: undefined
  });
  return obtenerUsuario(id);
};

export const obtenerCatalogoRoles = () => obtenerRolesDisponibles();

