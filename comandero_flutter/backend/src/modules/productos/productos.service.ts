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
import { nowMx } from '../../config/time.js';

const parseDuracionDescuento = (raw?: string | null): Date | null => {
  if (!raw) return null;
  const normalized = raw.trim().toLowerCase();
  const ahora = nowMx();

  const map: Record<string, { amount: number; unit: 'hours' | 'days' | 'weeks' | 'months' | 'years' }> = {
    '1h': { amount: 1, unit: 'hours' },
    '1 hora': { amount: 1, unit: 'hours' },
    '1 horas': { amount: 1, unit: 'hours' },
    '1 día': { amount: 1, unit: 'days' },
    '1 dia': { amount: 1, unit: 'days' },
    '2 días': { amount: 2, unit: 'days' },
    '2 dias': { amount: 2, unit: 'days' },
    '3 días': { amount: 3, unit: 'days' },
    '3 dias': { amount: 3, unit: 'days' },
    '1 semana': { amount: 1, unit: 'weeks' },
    '1 mes': { amount: 1, unit: 'months' },
    '1 año': { amount: 1, unit: 'years' },
    '1 ano': { amount: 1, unit: 'years' }
  };

  const mapped = map[normalized];
  if (mapped) return ahora.plus(mapped).toJSDate();

  const compact = normalized.match(/^(\d+)\s*(h|hora|horas|d|dia|día|dias|días|semana|semanas|mes|meses|año|ano|años|anos)$/);
  if (compact) {
    const value = Number(compact[1]);
    const unitRaw = compact[2];
    if (!Number.isFinite(value) || value <= 0) return null;
    if (['h', 'hora', 'horas'].includes(unitRaw)) return ahora.plus({ hours: value }).toJSDate();
    if (['d', 'dia', 'día', 'dias', 'días'].includes(unitRaw)) return ahora.plus({ days: value }).toJSDate();
    if (['semana', 'semanas'].includes(unitRaw)) return ahora.plus({ weeks: value }).toJSDate();
    if (['mes', 'meses'].includes(unitRaw)) return ahora.plus({ months: value }).toJSDate();
    if (['año', 'ano', 'años', 'anos'].includes(unitRaw)) return ahora.plus({ years: value }).toJSDate();
  }

  return null;
};

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

  const descuentoPorcentaje = input.descuentoPorcentaje ?? 0;
  const descuentoInicio = descuentoPorcentaje > 0 ? nowMx().toJSDate() : null;
  const descuentoFin = descuentoPorcentaje > 0 ? parseDuracionDescuento(input.duracionDescuento) : null;

  try {
    const id = await crearProducto({
      categoriaId: input.categoriaId,
      nombre: input.nombre.trim(),
      descripcion: input.descripcion ?? null,
      precio: precioBase,
      disponible: input.disponible ?? true,
      sku: input.sku ?? null,
      inventariable: input.inventariable ?? false,
      descuentoPorcentaje,
      descuentoInicio,
      descuentoFin,
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
        esPersonalizado: ingrediente.esPersonalizado ?? false,
        esOpcional: ingrediente.esOpcional ?? false,
        productoTamanoId: ingrediente.tamanoId ?? null
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

  let descuentoPorcentaje: number | undefined;
  let descuentoInicio: Date | null | undefined;
  let descuentoFin: Date | null | undefined;
  if (input.descuentoPorcentaje !== undefined) {
    const pct = Number(input.descuentoPorcentaje ?? 0);
    descuentoPorcentaje = pct;
    if (pct > 0) {
      descuentoInicio = nowMx().toJSDate();
      descuentoFin = parseDuracionDescuento(input.duracionDescuento) ?? null;
    } else {
      descuentoInicio = null;
      descuentoFin = null;
    }
  }

  await actualizarProducto(id, {
    categoriaId: input.categoriaId,
    nombre: input.nombre,
    descripcion: input.descripcion ?? null,
    precio,
    disponible: input.disponible,
    sku: input.sku ?? null,
    inventariable: input.inventariable,
    descuentoPorcentaje,
    descuentoInicio,
    descuentoFin,
    tamanos,
    ingredientes: input.ingredientes?.map((ingrediente) => ({
      inventarioItemId: ingrediente.inventarioItemId ?? null,
      categoria: ingrediente.categoria ?? null,
      nombre: ingrediente.nombre,
      unidad: ingrediente.unidad,
      cantidadPorPorcion: ingrediente.cantidadPorPorcion,
      descontarAutomaticamente: ingrediente.descontarAutomaticamente ?? true,
      esPersonalizado: ingrediente.esPersonalizado ?? false,
      esOpcional: ingrediente.esOpcional ?? false,
      productoTamanoId: ingrediente.tamanoId ?? null
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

