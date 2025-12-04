import {
  listarInsumos,
  obtenerInsumoPorId,
  crearInsumo,
  actualizarInsumo,
  desactivarInsumo,
  registrarMovimiento,
  listarMovimientos,
  obtenerCategoriasUnicas
} from './inventario.repository.js';
import type {
  ActualizarInsumoInput,
  CrearInsumoInput,
  CrearMovimientoInput
} from './inventario.schemas.js';
import { notFound } from '../../utils/http-error.js';

export const obtenerInsumos = () => listarInsumos();

export const obtenerInsumo = async (id: number) => {
  const insumo = await obtenerInsumoPorId(id);
  if (!insumo) {
    throw notFound('Insumo no encontrado');
  }
  return insumo;
};

export const crearNuevoInsumo = async (input: CrearInsumoInput) => {
  const id = await crearInsumo({
    nombre: input.nombre,
    categoria: input.categoria,
    unidad: input.unidad,
    cantidadActual: input.cantidadActual ?? 0,
    stockMinimo: input.stockMinimo ?? 0,
    stockMaximo: input.stockMaximo ?? null,
    costoUnitario: input.costoUnitario ?? null,
    proveedor: input.proveedor ?? null,
    activo: input.activo ?? true
  });
  return obtenerInsumo(id);
};

export const actualizarInsumoExistente = async (id: number, input: ActualizarInsumoInput) => {
  const existe = await obtenerInsumoPorId(id);
  if (!existe) {
    throw notFound('Insumo no encontrado');
  }
  await actualizarInsumo(id, {
    nombre: input.nombre,
    categoria: input.categoria,
    unidad: input.unidad,
    cantidadActual: input.cantidadActual,
    stockMinimo: input.stockMinimo,
    stockMaximo: input.stockMaximo ?? null,
    costoUnitario: input.costoUnitario ?? null,
    proveedor: input.proveedor ?? null,
    activo: input.activo
  });
  return obtenerInsumo(id);
};

export const desactivarInsumoExistente = async (id: number) => {
  const existe = await obtenerInsumoPorId(id);
  if (!existe) {
    throw notFound('Insumo no encontrado');
  }
  await desactivarInsumo(id);
};

export const registrarMovimientoInventario = async (
  input: CrearMovimientoInput,
  usuarioId?: number
) => {
  await obtenerInsumo(input.inventarioItemId); // valida existencia
  await registrarMovimiento({
    inventarioItemId: input.inventarioItemId,
    tipo: input.tipo,
    cantidad: input.cantidad,
    costoUnitario: input.costoUnitario ?? null,
    motivo: input.motivo ?? null,
    origen: input.origen ?? null,
    referenciaOrdenId: input.referenciaOrdenId ?? null,
    usuarioId: usuarioId ?? null
  });
  return obtenerInsumo(input.inventarioItemId);
};

export const obtenerMovimientos = (inventarioItemId?: number) =>
  listarMovimientos(inventarioItemId);

export const obtenerCategorias = async () => {
  const categorias = await obtenerCategoriasUnicas();
  // Retornar array vacío si no hay categorías, no agregar 'Otros' por defecto
  return categorias;
};

