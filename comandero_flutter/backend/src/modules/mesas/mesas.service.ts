import {
  listarMesas,
  obtenerMesaPorId,
  crearMesa,
  actualizarMesa,
  eliminarMesa,
  cambiarEstadoMesa,
  obtenerHistorialMesa,
  listarEstadosMesa
} from './mesas.repository.js';
import type {
  ActualizarMesaInput,
  CambiarEstadoMesaInput,
  CrearMesaInput
} from './mesas.schemas.js';
import { notFound } from '../../utils/http-error.js';
import { emitTableCreated, emitTableUpdated, emitTableDeleted } from '../../realtime/events.js';

export const obtenerMesas = () => listarMesas();

export const obtenerMesa = async (id: number) => {
  const mesa = await obtenerMesaPorId(id);
  if (!mesa) {
    throw notFound('Mesa no encontrada');
  }
  return mesa;
};

export const crearNuevaMesa = async (input: CrearMesaInput) => {
  const id = await crearMesa({
    codigo: input.codigo,
    nombre: input.nombre ?? null,
    capacidad: input.capacidad ?? null,
    ubicacion: input.ubicacion ?? null,
    estadoMesaId: input.estadoMesaId ?? null,
    activo: input.activo ?? true
  });
  const mesa = await obtenerMesa(id);
  emitTableCreated(mesa);
  return mesa;
};

export const actualizarMesaExistente = async (id: number, input: ActualizarMesaInput) => {
  const existe = await obtenerMesaPorId(id);
  if (!existe) {
    throw notFound('Mesa no encontrada');
  }
  await actualizarMesa(id, {
    codigo: input.codigo,
    nombre: input.nombre ?? null,
    capacidad: input.capacidad ?? null,
    ubicacion: input.ubicacion ?? null,
    estadoMesaId: input.estadoMesaId ?? null,
    activo: input.activo
  });
  const mesa = await obtenerMesa(id);
  emitTableUpdated(mesa);
  return mesa;
};

export const desactivarMesa = async (id: number) => {
  const existe = await obtenerMesaPorId(id);
  if (!existe) {
    throw notFound('Mesa no encontrada');
  }
  await eliminarMesa(id);
  emitTableDeleted(id);
};

export const cambiarEstadoDeMesa = async (
  id: number,
  input: CambiarEstadoMesaInput,
  usuarioId?: number
) => {
  const existe = await obtenerMesaPorId(id);
  if (!existe) {
    throw notFound('Mesa no encontrada');
  }
  await cambiarEstadoMesa({
    mesaId: id,
    estadoMesaId: input.estadoMesaId,
    usuarioId,
    nota: input.nota ?? null
  });
  const mesa = await obtenerMesa(id);
  emitTableUpdated(mesa);
  return mesa;
};

export const obtenerHistorialDeMesa = async (mesaId: number) => {
  await obtenerMesa(mesaId); // valida existencia
  return obtenerHistorialMesa(mesaId);
};

export const obtenerEstadosMesa = () => listarEstadosMesa();

