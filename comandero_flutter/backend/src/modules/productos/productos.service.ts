import {
  listarProductos,
  obtenerProductoPorId,
  crearProducto,
  actualizarProducto,
  desactivarProducto
} from './productos.repository.js';
import { obtenerCategoriaPorId } from '../categorias/categorias.repository.js';
import type {
  ActualizarProductoInput,
  CrearProductoInput
} from './productos.schemas.js';
import { notFound } from '../../utils/http-error.js';

const asegurarCategoriaExiste = async (categoriaId: number) => {
  const categoria = await obtenerCategoriaPorId(categoriaId);
  if (!categoria || !categoria.activo) {
    throw notFound('Categoría no encontrada o inactiva');
  }
};

export const obtenerProductos = (categoriaId?: number) => listarProductos(categoriaId);

export const obtenerProducto = async (id: number) => {
  const producto = await obtenerProductoPorId(id);
  if (!producto) {
    throw notFound('Producto no encontrado');
  }
  return producto;
};

export const crearNuevoProducto = async (input: CrearProductoInput) => {
  await asegurarCategoriaExiste(input.categoriaId);
  const tieneTamanos = input.tamanos !== undefined && input.tamanos.length > 0;
  const precioBase = tieneTamanos ? input.tamanos![0].precio : input.precio;

  if (precioBase === undefined) {
    throw new Error('Debe proporcionar un precio base para el producto');
  }

  try {
    const id = await crearProducto({
      categoriaId: input.categoriaId,
      nombre: input.nombre.trim(),
      descripcion: input.descripcion ?? null,
      precio: precioBase,
      disponible: input.disponible ?? true,
      sku: input.sku ?? null,
      inventariable: input.inventariable ?? false,
      tamanos: tieneTamanos
        ? input.tamanos!.map((tamano) => ({
            nombre: tamano.nombre.trim(),
            precio: tamano.precio
          }))
        : undefined,
      ingredientes: input.ingredientes?.map((ingrediente) => ({
        inventarioItemId: ingrediente.inventarioItemId ?? null,
        categoria: ingrediente.categoria ?? null,
        nombre: ingrediente.nombre.trim(),
        unidad: ingrediente.unidad.trim(),
        cantidadPorPorcion: ingrediente.cantidadPorPorcion,
        descontarAutomaticamente: ingrediente.descontarAutomaticamente ?? true,
        esPersonalizado: ingrediente.esPersonalizado ?? false
      }))
    });
    return obtenerProducto(id);
  } catch (error: any) {
    // Manejar errores de duplicado de manera más clara
    if (error.code === 'ER_DUP_ENTRY' || error.message?.includes('Duplicate entry')) {
      const errorMessage = error.message || '';
      if (errorMessage.includes('ux_producto_categoria_nombre') || errorMessage.includes('categoria_nombre')) {
        throw new Error(`Ya existe un producto con el nombre "${input.nombre.trim()}" en esta categoría. Por favor, usa un nombre diferente.`);
      }
      throw new Error(`Ya existe un producto con estos datos. Por favor, verifica la información e intenta nuevamente.`);
    }
    throw error;
  }
};

export const actualizarProductoExistente = async (id: number, input: ActualizarProductoInput) => {
  const existe = await obtenerProductoPorId(id);
  if (!existe) {
    throw notFound('Producto no encontrado');
  }
  if (input.categoriaId !== undefined) {
    await asegurarCategoriaExiste(input.categoriaId);
  }
  const tieneTamanos = input.tamanos !== undefined;
  const tamanos = tieneTamanos
    ? input.tamanos?.map((tamano) => ({
        nombre: tamano.nombre,
        precio: tamano.precio
      })) ?? []
    : undefined;

  let precio = input.precio;
  if (tieneTamanos && input.tamanos && input.tamanos.length > 0) {
    precio = input.tamanos[0].precio;
  }

  await actualizarProducto(id, {
    categoriaId: input.categoriaId,
    nombre: input.nombre,
    descripcion: input.descripcion ?? null,
    precio,
    disponible: input.disponible,
    sku: input.sku ?? null,
    inventariable: input.inventariable,
    tamanos,
    ingredientes: input.ingredientes?.map((ingrediente) => ({
      inventarioItemId: ingrediente.inventarioItemId ?? null,
      categoria: ingrediente.categoria ?? null,
      nombre: ingrediente.nombre,
      unidad: ingrediente.unidad,
      cantidadPorPorcion: ingrediente.cantidadPorPorcion,
      descontarAutomaticamente: ingrediente.descontarAutomaticamente ?? true,
      esPersonalizado: ingrediente.esPersonalizado ?? false
    }))
  });
  return obtenerProducto(id);
};

export const desactivarProductoExistente = async (id: number) => {
  const existe = await obtenerProductoPorId(id);
  if (!existe) {
    throw notFound('Producto no encontrado');
  }
  await desactivarProducto(id);
};

