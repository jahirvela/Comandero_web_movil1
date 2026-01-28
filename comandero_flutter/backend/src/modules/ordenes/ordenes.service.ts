import {
  listarOrdenes,
  obtenerOrdenBasePorId,
  obtenerItemsOrden,
  obtenerModificadoresItem,
  crearOrden,
  actualizarOrden,
  actualizarEstadoOrden,
  actualizarTiempoEstimadoPreparacion,
  agregarItemsAOrden,
  listarEstadosOrden,
  obtenerEstadoOrdenPorNombre,
  recalcularTotalesOrden
} from './ordenes.repository.js';
import type {
  ActualizarEstadoOrdenInput,
  ActualizarOrdenInput,
  AgregarItemInput,
  CrearOrdenInput,
  OrdenItemInput
} from './ordenes.schemas.js';
import { notFound, badRequest } from '../../utils/http-error.js';
import type { OrdenDetalle } from '../../types/ordenes.js';
import { emitOrderCreated, emitOrderCancelled, emitOrderUpdated } from '../../realtime/events.js';
import { emitirAlertaPedidoListo, emitirAlertaPedidoEnPreparacion } from '../alertas/alertas.service.js';
import { utcToMxISO } from '../../config/time.js';
import { logger } from '../../config/logger.js';

const obtenerEstadoOrdenId = async (estadoOrdenId?: number) => {
  if (estadoOrdenId) {
    const estados = await listarEstadosOrden();
    const encontrado = estados.find((estado) => estado.id === estadoOrdenId);
    if (!encontrado) {
      throw badRequest('Estado de orden inválido');
    }
    return estadoOrdenId;
  }
  const estadoPorDefecto = await obtenerEstadoOrdenPorNombre('abierta');
  if (!estadoPorDefecto) {
    throw badRequest('No se encontró el estado "abierta" en la base de datos');
  }
  return estadoPorDefecto.id;
};

const calcularTotales = (items: OrdenItemInput[]) => {
  let subtotal = 0;
  for (const item of items) {
    const modificadoresTotal =
      (item.modificadores ?? []).reduce(
        (acc, mod) => acc + (mod.precioUnitario ?? 0),
        0
      ) * item.cantidad;
    subtotal += item.cantidad * item.precioUnitario + modificadoresTotal;
  }
  return { subtotal };
};

export const obtenerOrdenes = (filters: { estadoOrdenId?: number; mesaId?: number }) =>
  listarOrdenes(filters);

export const obtenerOrdenDetalle = async (id: number): Promise<OrdenDetalle> => {
  const base = await obtenerOrdenBasePorId(id);
  if (!base) {
    throw notFound('Orden no encontrada');
  }
  const items = await obtenerItemsOrden(id);
  const modificadores = await obtenerModificadoresItem(items.map((item) => item.id));
  const modificadoresPorItem = new Map<number, typeof modificadores>();
  for (const mod of modificadores) {
    const list = modificadoresPorItem.get(mod.ordenItemId) ?? [];
    list.push(mod);
    modificadoresPorItem.set(mod.ordenItemId, list);
  }

  // Usar tiempo estimado del cocinero si existe, sino usar 6 minutos por defecto
  const tiempoEstimadoPreparacion = (base as any).tiempoEstimadoPreparacion;
  const defaultEstimatedTime = 6; // 6 minutos por defecto
  const estimatedTime = tiempoEstimadoPreparacion 
    ? Number(tiempoEstimadoPreparacion)
    : defaultEstimatedTime;

  // Serializar fechas a ISO string para JSON (ya convertidas a zona CDMX en el repository)
  return {
    ...base,
    clienteTelefono: (base as any).clienteTelefono ?? null,
    creadoEn: utcToMxISO(base.creadoEn) ?? base.creadoEn,
    actualizadoEn: utcToMxISO(base.actualizadoEn) ?? base.actualizadoEn,
    estimatedTime,
    tiempoEstimadoPreparacion: tiempoEstimadoPreparacion ? Number(tiempoEstimadoPreparacion) : defaultEstimatedTime,
    pickupTime: null, // Se puede agregar después si se necesita
    items: items.map((item) => ({
      ...item,
      modificadores: modificadoresPorItem.get(item.id) ?? []
    }))
  } as any; // Usar any temporalmente para permitir strings en lugar de Date
};

export const crearNuevaOrden = async (input: CrearOrdenInput, usuarioId?: number) => {
  const estadoOrdenId = await obtenerEstadoOrdenId(input.estadoOrdenId);
  const { subtotal } = calcularTotales(input.items);
  const descuentoTotal = input.descuentoTotal ?? 0;
  const impuestoTotal = input.impuestoTotal ?? 0;
  const propinaSugerida = input.propinaSugerida ?? 0;
  const total = subtotal - descuentoTotal + impuestoTotal + propinaSugerida;

  const ordenId = await crearOrden({
    mesaId: input.mesaId ?? null,
    reservaId: input.reservaId ?? null,
    clienteId: input.clienteId ?? null,
    clienteNombre: input.clienteNombre ?? null,
    subtotal,
    descuentoTotal,
    impuestoTotal,
    propinaSugerida: input.propinaSugerida ?? null,
    total,
    estadoOrdenId,
    creadoPorUsuarioId: usuarioId ?? null,
    items: input.items.map((item) => ({
      productoId: item.productoId,
      productoTamanoId: item.productoTamanoId ?? null,
      cantidad: item.cantidad,
      precioUnitario: item.precioUnitario,
      nota: item.nota ?? null,
      modificadores: item.modificadores?.map((mod) => ({
        modificadorOpcionId: mod.modificadorOpcionId,
        precioUnitario: mod.precioUnitario ?? 0
      }))
    }))
  });

  const orden = await obtenerOrdenDetalle(ordenId);
  await emitOrderCreated(orden);
  return orden;
};

export const actualizarOrdenExistente = async (
  id: number,
  input: ActualizarOrdenInput,
  usuarioId?: number,
  username?: string,
  rol?: string
) => {
  const existe = await obtenerOrdenBasePorId(id);
  if (!existe) {
    throw notFound('Orden no encontrada');
  }
  await actualizarOrden(id, {
    mesaId: input.mesaId ?? null,
    reservaId: input.reservaId ?? null,
    clienteId: input.clienteId ?? null,
    clienteNombre: input.clienteNombre ?? null
  });
  const orden = await obtenerOrdenDetalle(id);
  await emitOrderUpdated(orden, usuarioId, username, rol, 'Orden actualizada');
  return orden;
};

// Helper para formatear nombre de estado (quitar guiones bajos y capitalizar)
const formatearNombreEstado = (nombreEstado: string): string => {
  return nombreEstado
    .replace(/_/g, ' ') // Reemplazar guiones bajos con espacios
    .split(' ')
    .map(palabra => palabra.charAt(0).toUpperCase() + palabra.slice(1).toLowerCase())
    .join(' ');
};

export const actualizarEstadoDeOrden = async (
  id: number,
  input: ActualizarEstadoOrdenInput,
  usuarioId?: number,
  username?: string,
  rol?: string
) => {
  const existe = await obtenerOrdenBasePorId(id);
  if (!existe) {
    throw notFound('Orden no encontrada');
  }
  const estados = await listarEstadosOrden();
  const estadoValido = estados.find((estado) => estado.id === input.estadoOrdenId);
  if (!estadoValido) {
    throw badRequest('Estado de orden inválido');
  }
  await actualizarEstadoOrden(id, input.estadoOrdenId, usuarioId ?? null);
  const orden = await obtenerOrdenDetalle(id);
  
  // Formatear nombre del estado y verificar si es estado de preparación
  const estadoNombreFormateado = formatearNombreEstado(estadoValido.nombre);
  const estadoNombreLower = estadoValido.nombre.toLowerCase();
  const esEstadoPreparacion = estadoNombreLower.includes('preparacion') || 
                               estadoNombreLower.includes('preparación') || 
                               estadoNombreLower.includes('cooking') || 
                               estadoNombreLower.includes('iniciar');
  
  // Construir mensaje de cambio con tiempo estimado si corresponde
  let mensajeCambio = `Estado cambiado a: ${estadoNombreFormateado}`;
  
  // Si es estado de preparación, agregar tiempo estimado (6 min por defecto si no está definido)
  if (esEstadoPreparacion) {
    const tiempoEstimado = orden.tiempoEstimadoPreparacion ?? 6; // 6 minutos por defecto
    const tiempoNum = Number(tiempoEstimado);
    if (tiempoNum > 0) {
      let tiempoTexto = '';
      if (tiempoNum >= 60) {
        const horas = Math.floor(tiempoNum / 60);
        const minutos = tiempoNum % 60;
        tiempoTexto = minutos > 0 
          ? `${horas}h ${minutos}min`
          : `${horas}h`;
      } else {
        tiempoTexto = `${tiempoNum}min`;
      }
      mensajeCambio = `Estado cambiado a: ${estadoNombreFormateado} (estimado: ${tiempoTexto})`;
    }
  }
  
  await emitOrderUpdated(orden, usuarioId, username, rol, mensajeCambio);
  
  // Logging para debugging
  logger.info({
    ordenId: id,
    estadoId: input.estadoOrdenId,
    estadoNombre: estadoValido.nombre,
    usuarioId,
    username,
    rol,
    tieneDatosUsuario: !!(usuarioId && username && rol)
  }, '🔄 Estado de orden actualizado - verificando si se debe emitir alerta');
  
  logger.info({
    estadoNombre: estadoValido.nombre,
    estadoNombreLower,
    esEstadoPreparacion,
    tieneDatosUsuario: !!(usuarioId && username && rol)
  }, `🔍 Verificación de estado "preparación": ${esEstadoPreparacion}`);
  
  if (esEstadoPreparacion && usuarioId && username && rol) {
    const isTakeaway = orden.mesaId == null;
    logger.info({ 
      ordenId: orden.id,
      estado: estadoValido.nombre,
      usuarioId,
      username,
      rol,
      isTakeaway,
      mesaId: orden.mesaId,
      mesaCodigo: orden.mesaCodigo
    }, '🔔 Estado "en preparación" detectado, emitiendo alerta al mesero');
    
    // Emitir alerta de preparación y ESPERAR a que se complete
    logger.info({ ordenId: orden.id }, '🚀 LLAMANDO a emitirAlertaPedidoEnPreparacion...');
    emitirAlertaPedidoEnPreparacion(
      orden.id,
      orden.mesaId ?? null,
      orden.mesaCodigo ?? null,
      usuarioId,
      username,
      rol,
      isTakeaway
    ).then(() => {
      logger.info({ ordenId: orden.id }, '✅ emitirAlertaPedidoEnPreparacion COMPLETADA');
    }).catch((error) => {
      logger.error({ err: error, ordenId: orden.id }, '❌ Error al emitir alerta de pedido en preparación');
    });
  } else if (esEstadoPreparacion) {
    logger.warn({ 
      ordenId: orden.id,
      usuarioId,
      username,
      rol 
    }, '⚠️ No se puede emitir alerta de preparación: faltan datos de usuario');
  }
  
  // Verificar si el estado es "listo" o "listo para recoger" y emitir alerta al mesero INMEDIATAMENTE
  const esEstadoListo = estadoNombreLower.includes('listo') || 
                        estadoNombreLower.includes('ready') ||
                        estadoNombreLower === 'listo_para_recoger';
  
  // Descontar inventario automáticamente cuando se marca como "listo"
  if (esEstadoListo) {
    try {
      const { descontarInventarioPorReceta } = await import('../inventario/inventario.service.js');
      // Ejecutar descuento automático en segundo plano (no bloquear la actualización del estado)
      descontarInventarioPorReceta(orden.id, usuarioId ?? undefined).catch((error) => {
        logger.error({ err: error, ordenId: orden.id }, '❌ Error en descuento automático de inventario');
      });
    } catch (error) {
      logger.error({ err: error, ordenId: orden.id }, '❌ Error al importar servicio de descuento automático');
    }
  }
  
  if (esEstadoListo && usuarioId && username && rol) {
    const isTakeaway = orden.mesaId == null;
    logger.info({ 
      ordenId: orden.id,
      estado: estadoValido.nombre,
      estadoNombreLower,
      esEstadoListo,
      usuarioId,
      username,
      rol,
      isTakeaway,
      mesaId: orden.mesaId,
      mesaCodigo: orden.mesaCodigo
    }, '🔔 Estado "listo" detectado, emitiendo alerta al mesero');
    
    // Emitir alerta y ESPERAR a que se complete (usar await para asegurar que se complete)
    logger.info({ ordenId: orden.id }, '🚀 LLAMANDO a emitirAlertaPedidoListo...');
    try {
      await emitirAlertaPedidoListo(
        orden.id,
        orden.mesaId ?? null,
        orden.mesaCodigo ?? null,
        usuarioId,
        username,
        rol,
        isTakeaway
      );
      logger.info({ ordenId: orden.id }, '✅ emitirAlertaPedidoListo COMPLETADA');
    } catch (error) {
      logger.error({ err: error, ordenId: orden.id }, '❌ Error al emitir alerta de pedido listo');
      // No re-lanzar el error para que no afecte la actualización del estado
    }
  } else if (esEstadoListo) {
    logger.warn({ 
      ordenId: orden.id,
      estadoNombre: estadoValido.nombre,
      usuarioId,
      username,
      rol 
    }, '⚠️ No se puede emitir alerta de listo: faltan datos de usuario');
  }
  
  const estadoCancelada = await obtenerEstadoOrdenPorNombre('cancelada');
  if (estadoCancelada && input.estadoOrdenId === estadoCancelada.id) {
    await emitOrderCancelled(orden, 'Orden cancelada', usuarioId, username, rol);
  }
  return orden;
};

export const agregarItemsOrden = async (
  id: number,
  input: AgregarItemInput,
  usuarioId?: number,
  username?: string,
  rol?: string
) => {
  const existe = await obtenerOrdenBasePorId(id);
  if (!existe) {
    throw notFound('Orden no encontrada');
  }
  await agregarItemsAOrden(
    id,
    input.items.map((item) => ({
      productoId: item.productoId,
      productoTamanoId: item.productoTamanoId ?? null,
      cantidad: item.cantidad,
      precioUnitario: item.precioUnitario,
      nota: item.nota ?? null,
      modificadores: item.modificadores?.map((mod) => ({
        modificadorOpcionId: mod.modificadorOpcionId,
        precioUnitario: mod.precioUnitario ?? 0
      }))
    }))
  );
  await recalcularTotalesOrden(id);
  const orden = await obtenerOrdenDetalle(id);
  await emitOrderUpdated(orden, usuarioId, username, rol, `Se agregaron ${input.items.length} item(s)`);
  return orden;
};

export const obtenerEstadosOrdenServicio = () => listarEstadosOrden();

export const actualizarTiempoEstimado = async (
  ordenId: number,
  tiempoEstimado: number,
  usuarioId?: number,
  username?: string,
  rol?: string
) => {
  const existe = await obtenerOrdenBasePorId(ordenId);
  if (!existe) {
    throw notFound('Orden no encontrada');
  }

  // Validar que el tiempo esté en un rango razonable (1-120 minutos)
  if (tiempoEstimado < 1 || tiempoEstimado > 120) {
    throw badRequest('El tiempo estimado debe estar entre 1 y 120 minutos');
  }

  await actualizarTiempoEstimadoPreparacion(ordenId, tiempoEstimado);
  const orden = await obtenerOrdenDetalle(ordenId);
  
  // Emitir actualización en tiempo real
  await emitOrderUpdated(orden, usuarioId, username, rol, `Tiempo estimado actualizado a ${tiempoEstimado} minutos`);
  
  logger.info({
    ordenId,
    tiempoEstimado,
    usuarioId,
    username,
    rol
  }, '⏱️ Tiempo estimado de preparación actualizado');
  
  return orden;
};

