import {
  listarCategorias,
  obtenerCategoriaPorId,
  crearCategoria,
  actualizarCategoria,
  eliminarCategoria,
  contarProductosEnCategoria
} from './categorias.repository.js';
import type {
  ActualizarCategoriaInput,
  CrearCategoriaInput
} from './categorias.schemas.js';
import { notFound, forbidden, conflict } from '../../utils/http-error.js';

const esNombreCategoriaTodosReservada = (nombre: string) =>
  nombre.trim().toLowerCase() === 'todos';

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
  if (esNombreCategoriaTodosReservada(existe.nombre)) {
    throw forbidden('No se puede eliminar la categoría «Todos».');
  }
  const numProductos = await contarProductosEnCategoria(id);
  if (numProductos > 0) {
    throw conflict(
      'No se puede eliminar la categoría porque tiene productos asignados. Reasigne los productos a otra categoría o elimínelos primero.'
    );
  }
  await eliminarCategoria(id);
};

