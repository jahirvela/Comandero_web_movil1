import {
  listarCategorias,
  obtenerCategoriaPorId,
  crearCategoria,
  actualizarCategoria,
  eliminarCategoria
} from './categorias.repository.js';
import type {
  ActualizarCategoriaInput,
  CrearCategoriaInput
} from './categorias.schemas.js';
import { notFound } from '../../utils/http-error.js';

export const obtenerCategorias = () => listarCategorias();

export const obtenerCategoria = async (id: number) => {
  const categoria = await obtenerCategoriaPorId(id);
  if (!categoria) {
    throw notFound('Categoría no encontrada');
  }
  return categoria;
};

export const crearNuevaCategoria = async (input: CrearCategoriaInput) => {
  const id = await crearCategoria({
    nombre: input.nombre,
    descripcion: input.descripcion ?? null,
    activo: input.activo ?? true
  });
  return obtenerCategoria(id);
};

export const actualizarCategoriaExistente = async (id: number, input: ActualizarCategoriaInput) => {
  const existe = await obtenerCategoriaPorId(id);
  if (!existe) {
    throw notFound('Categoría no encontrada');
  }
  await actualizarCategoria(id, {
    nombre: input.nombre,
    descripcion: input.descripcion ?? null,
    activo: input.activo
  });
  return obtenerCategoria(id);
};

export const eliminarCategoriaExistente = async (id: number) => {
  const existe = await obtenerCategoriaPorId(id);
  if (!existe) {
    throw notFound('Categoría no encontrada');
  }
  await eliminarCategoria(id);
};

