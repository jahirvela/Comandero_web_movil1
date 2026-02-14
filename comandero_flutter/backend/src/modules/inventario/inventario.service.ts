import {
  listarInsumos,
  obtenerInsumoPorId,
  obtenerInsumoPorCodigoBarras,
  crearInsumo,
  actualizarInsumo,
  desactivarInsumo,
  registrarMovimiento,
  listarMovimientos,
  obtenerCategoriasUnicas,
  existeMovimientoConReferenciaOrden,
  crearCategoriaInventario as crearCategoriaInventarioRepo
} from './inventario.repository.js';
import type {
  ActualizarInsumoInput,
  CrearInsumoInput,
  CrearMovimientoInput
} from './inventario.schemas.js';
import { notFound } from '../../utils/http-error.js';
import { logger } from '../../config/logger.js';

export const obtenerInsumos = () => listarInsumos();

export const obtenerInsumo = async (id: number) => {
  const insumo = await obtenerInsumoPorId(id);
  if (!insumo) {
    throw notFound('Insumo no encontrado');
  }
  return insumo;
};

/** Obtiene un ítem de inventario por código de barras (para escanear y ajustar cantidad). */
export const obtenerInsumoPorCodigoBarrasService = (codigo: string) =>
  obtenerInsumoPorCodigoBarras(codigo);

export const crearNuevoInsumo = async (input: CrearInsumoInput) => {
  const id = await crearInsumo({
    nombre: input.nombre,
    codigoBarras: input.codigoBarras ?? null,
    categoria: input.categoria,
    unidad: input.unidad,
    cantidadActual: input.cantidadActual ?? 0,
    stockMinimo: input.stockMinimo ?? 0,
    stockMaximo: input.stockMaximo ?? null,
    costoUnitario: input.costoUnitario ?? null,
    proveedor: input.proveedor ?? null,
    activo: input.activo ?? true,
    contenidoPorPieza: input.contenidoPorPieza ?? null,
    unidadContenido: input.unidadContenido ?? null
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
    codigoBarras: input.codigoBarras,
    categoria: input.categoria,
    unidad: input.unidad,
    cantidadActual: input.cantidadActual,
    stockMinimo: input.stockMinimo,
    stockMaximo: input.stockMaximo ?? null,
    costoUnitario: input.costoUnitario ?? null,
    proveedor: input.proveedor ?? null,
    activo: input.activo,
    contenidoPorPieza: input.contenidoPorPieza,
    unidadContenido: input.unidadContenido
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
  const itemAntes = await obtenerInsumo(input.inventarioItemId); // valida existencia
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
  const itemDespues = await obtenerInsumo(input.inventarioItemId);
  // Emitir alerta de inventario si el movimiento hizo cruzar el umbral de stock mínimo
  if (itemDespues) {
    const cruzoMinimo =
      itemAntes.cantidadActual > itemAntes.stockMinimo &&
      itemDespues.cantidadActual <= itemDespues.stockMinimo;
    const cruzoSinStock =
      itemAntes.cantidadActual > 0 && itemDespues.cantidadActual <= 0;
    if (cruzoMinimo || cruzoSinStock) {
      const { emitirAlertaInventario } = await import('../alertas/alertas.service.js');
      emitirAlertaInventario(
        {
          id: itemDespues.id,
          nombre: itemDespues.nombre,
          cantidadActual: itemDespues.cantidadActual,
          stockMinimo: itemDespues.stockMinimo,
          unidad: itemDespues.unidad
        },
        usuarioId ?? undefined
      ).catch((err) =>
        logger.warn(
          { err, inventarioItemId: input.inventarioItemId },
          'No se pudo emitir alerta de inventario'
        )
      );
    }
  }
  return itemDespues!;
};

export const obtenerMovimientos = (inventarioItemId?: number) =>
  listarMovimientos(inventarioItemId);

export const obtenerCategorias = async () => {
  const categorias = await obtenerCategoriasUnicas();
  return categorias;
};

/** Crea una categoría de inventario (persistida) para que no desaparezca al recargar. */
export const crearCategoriaInventario = async (nombre: string): Promise<string[]> => {
  const n = nombre.trim();
  if (!n) return obtenerCategorias();
  await crearCategoriaInventarioRepo(n);
  return obtenerCategorias();
};

/** Decimales para cantidades convertidas (evitar flotante y almacenar limpio) */
const DECIMALES_CANTIDAD = 6;

/** Unidades de peso reconocidas (origen/destino) */
const UNIDADES_PESO_G = ['g', 'gr', 'gramo', 'gramos', 'grama', 'gramas'];
const UNIDADES_PESO_KG = ['kg', 'kilogramo', 'kilogramos', 'kilo', 'kilos'];

/** Unidades de volumen reconocidas */
const UNIDADES_VOL_L = ['l', 'lt', 'lts', 'litro', 'litros'];
const UNIDADES_VOL_ML = ['ml', 'mililitro', 'mililitros'];

/** Unidades por pieza (sin conversión: 1 pieza = 1 pieza, pza = piezas, etc.) */
const UNIDADES_PIEZA = [
  'pza', 'pzas', 'pieza', 'piezas', 'unidad', 'unidades', 'ud', 'uds',
  'u', 'unit', 'units', 'pc', 'pcs', 'pz', 'pzs'
];

const perteneceA = (unidad: string, opciones: string[]) =>
  opciones.some((u) => u === unidad);

const perteneceAPieza = (unidad: string): boolean =>
  UNIDADES_PIEZA.includes(unidad.toLowerCase().trim());

/**
 * Convierte una cantidad de una unidad a otra compatible.
 * La receta puede estar en g (ej. 30 g por taco) y el inventario en Kg; se descuenta en la unidad del inventario.
 * Soporta también unidades por pieza (pza, pieza, piezas, etc.): conversión 1:1.
 * @param cantidad Cantidad en unidadOrigen
 * @param unidadOrigen Unidad de la receta (ej: "g", "gr", "kg", "ml", "L", "pza", "piezas")
 * @param unidadDestino Unidad del ítem en inventario (ej: "Kg", "g", "L", "ml", "pza")
 * @returns Cantidad convertida a unidadDestino, o null si no hay conversión compatible
 */
const convertirUnidad = (
  cantidad: number,
  unidadOrigen: string,
  unidadDestino: string
): number | null => {
  const o = unidadOrigen.toLowerCase().trim();
  const d = unidadDestino.toLowerCase().trim();

  if (o === d) return redondearCantidad(cantidad);

  // Por pieza: cualquier variante (pza, pieza, piezas, unidad, etc.) es compatible 1:1
  if (perteneceAPieza(unidadOrigen) && perteneceAPieza(unidadDestino)) {
    return redondearCantidad(cantidad);
  }

  // Peso: misma categoría (ej. kg ↔ kilogramos) = 1:1
  if (perteneceA(o, UNIDADES_PESO_KG) && perteneceA(d, UNIDADES_PESO_KG)) {
    return redondearCantidad(cantidad);
  }
  if (perteneceA(o, UNIDADES_PESO_G) && perteneceA(d, UNIDADES_PESO_G)) {
    return redondearCantidad(cantidad);
  }
  if (perteneceA(o, UNIDADES_PESO_KG) && perteneceA(d, UNIDADES_PESO_G)) {
    return redondearCantidad(cantidad * 1000);
  }
  if (perteneceA(o, UNIDADES_PESO_G) && perteneceA(d, UNIDADES_PESO_KG)) {
    return redondearCantidad(cantidad / 1000);
  }

  // Volumen: misma categoría (ej. L ↔ litros, ml ↔ mililitros) = 1:1
  if (perteneceA(o, UNIDADES_VOL_L) && perteneceA(d, UNIDADES_VOL_L)) {
    return redondearCantidad(cantidad);
  }
  if (perteneceA(o, UNIDADES_VOL_ML) && perteneceA(d, UNIDADES_VOL_ML)) {
    return redondearCantidad(cantidad);
  }
  if (perteneceA(o, UNIDADES_VOL_L) && perteneceA(d, UNIDADES_VOL_ML)) {
    return redondearCantidad(cantidad * 1000);
  }
  if (perteneceA(o, UNIDADES_VOL_ML) && perteneceA(d, UNIDADES_VOL_L)) {
    return redondearCantidad(cantidad / 1000);
  }

  return null;
};

const redondearCantidad = (n: number): number =>
  Math.round(n * Math.pow(10, DECIMALES_CANTIDAD)) / Math.pow(10, DECIMALES_CANTIDAD);

/**
 * Convierte cantidad de receta a la unidad del inventario.
 * Si el ítem está en piezas y tiene contenido por pieza (ej. 5 kg por envase), convierte
 * la cantidad de la receta (ej. 50 g) a la unidad de contenido y luego a piezas (50 g → 0.05 kg → 0.01 pza).
 */
const cantidadEnUnidadInventario = (
  cantidad: number,
  unidadReceta: string,
  item: { unidad: string; contenidoPorPieza?: number | null; unidadContenido?: string | null }
): number | null => {
  const unidadInv = item.unidad.trim();
  const esPieza = perteneceAPieza(unidadInv);
  const contenido = (item as any).contenidoPorPieza;
  const unidadCont = (item as any).unidadContenido?.trim();
  const tieneContenidoPorPieza = esPieza && contenido != null && contenido > 0 && unidadCont;
  if (tieneContenidoPorPieza) {
    const enContenido = convertirUnidad(cantidad, unidadReceta, unidadCont);
    if (enContenido !== null) {
      return redondearCantidad(enContenido / Number(contenido));
    }
  }
  return convertirUnidad(cantidad, unidadReceta, unidadInv);
};

/** Compara IDs de tamaño de receta vs ítem de orden (tolera number/string). Ingrediente sin tamaño aplica a todos. */
const tamanoIdCoincide = (
  ingrTamanoId: number | null | undefined,
  itemTamanoId: number | null | undefined
): boolean => {
  if (ingrTamanoId == null) return true;
  if (itemTamanoId == null) return false;
  return Number(ingrTamanoId) === Number(itemTamanoId);
};

export type FaltanteInventario = {
  nombre: string;
  requerido: number;
  disponible: number;
  unidad: string;
};

/**
 * Verifica si hay stock suficiente para preparar todos los ingredientes de una orden.
 * Se usa antes de permitir marcar la orden como "listo" / "listo para recoger".
 * @param ordenId ID de la orden
 * @returns { ok: true } si hay stock para todo; { ok: false, faltantes } si falta algún ingrediente
 */
export const verificarStockDisponibleParaOrden = async (
  ordenId: number
): Promise<{ ok: boolean; faltantes: FaltanteInventario[] }> => {
  const faltantes: FaltanteInventario[] = [];
  try {
    const { obtenerItemsOrden } = await import('../ordenes/ordenes.repository.js');
    const { obtenerIngredientesPorProductoIds } = await import('../productos/productos.repository.js');

    const items = await obtenerItemsOrden(ordenId);
    if (items.length === 0) {
      return { ok: true, faltantes: [] };
    }

    const productoIds = [...new Set(items.map((item: any) => item.productoId))];
    const ingredientesMap = await obtenerIngredientesPorProductoIds(productoIds);

    type AporteReceta = { cantidad: number; unidad: string; nombre: string };
    const aportesPorIngrediente = new Map<number, AporteReceta[]>();

    for (const item of items) {
      const ingredientes = ingredientesMap.get(item.productoId) || [];
      const cantidadProducto = item.cantidad;
      const itemTamanoId = item.productoTamanoId ?? null;
      // Receta por tamaño: solo ingredientes del tamaño del ítem o sin tamaño (aplican a todos).
      for (const ingrediente of ingredientes) {
        if (ingrediente.productoTamanoId != null && !tamanoIdCoincide(ingrediente.productoTamanoId, itemTamanoId)) {
          continue;
        }
        if (ingrediente.descontarAutomaticamente && ingrediente.inventarioItemId) {
          const cantidadAporte = ingrediente.cantidadPorPorcion * cantidadProducto;
          const lista = aportesPorIngrediente.get(ingrediente.inventarioItemId) ?? [];
          lista.push({
            cantidad: cantidadAporte,
            unidad: (ingrediente.unidad || 'g').trim(),
            nombre: ingrediente.nombre
          });
          aportesPorIngrediente.set(ingrediente.inventarioItemId, lista);
        }
      }
    }

    if (aportesPorIngrediente.size === 0) {
      return { ok: true, faltantes: [] };
    }

    for (const [inventarioItemId, aportes] of aportesPorIngrediente.entries()) {
      const itemInventario = await obtenerInsumoPorId(inventarioItemId);
      if (!itemInventario) {
        continue;
      }

      const unidadInventario = itemInventario.unidad.trim();
      let cantidadRequerida = 0;

      for (const aporte of aportes) {
        const convertida = cantidadEnUnidadInventario(aporte.cantidad, aporte.unidad, itemInventario);
        if (convertida === null) continue;
        cantidadRequerida += convertida;
      }

      cantidadRequerida = redondearCantidad(cantidadRequerida);
      if (cantidadRequerida <= 0) continue;

      const disponible = itemInventario.cantidadActual;
      if (disponible < cantidadRequerida) {
        faltantes.push({
          nombre: itemInventario.nombre,
          requerido: cantidadRequerida,
          disponible,
          unidad: itemInventario.unidad
        });
      }
    }

    return {
      ok: faltantes.length === 0,
      faltantes
    };
  } catch (error: any) {
    logger.error({ err: error, ordenId }, '❌ Error al verificar stock para orden');
    return { ok: true, faltantes: [] }; // En caso de error, no bloquear (comportamiento conservador)
  }
};

/**
 * Descontar automáticamente inventario basado en recetas de productos cuando una orden se marca como "listo"
 * @param ordenId ID de la orden
 * @param usuarioId ID del usuario que marcó como listo (opcional)
 */
export const descontarInventarioPorReceta = async (
  ordenId: number,
  usuarioId?: number
) => {
  try {
    // Evitar descontar dos veces la misma orden (p. ej. si se marca "listo" dos veces)
    const yaDescontado = await existeMovimientoConReferenciaOrden(ordenId);
    if (yaDescontado) {
      logger.info({ ordenId }, '📦 Orden ya tenía descuento de inventario, omitiendo');
      return;
    }

    // Importar funciones necesarias
    const { obtenerItemsOrden } = await import('../ordenes/ordenes.repository.js');
    const { obtenerIngredientesPorProductoIds } = await import('../productos/productos.repository.js');
    
    // Obtener items de la orden
    const items = await obtenerItemsOrden(ordenId);
    
    if (items.length === 0) {
      logger.info({ ordenId }, '📦 No hay items en la orden, no se descuenta inventario');
      return;
    }
    
    // Obtener IDs de productos únicos
    const productoIds = [...new Set(items.map(item => item.productoId))];
    
    // Obtener recetas (ingredientes) de todos los productos
    const ingredientesMap = await obtenerIngredientesPorProductoIds(productoIds);
    
    // Acumular aportes por ingrediente: cada uno con su cantidad y unidad (receta puede usar g, inventario Kg, etc.)
    type AporteReceta = { cantidad: number; unidad: string; nombre: string };
    const aportesPorIngrediente = new Map<number, AporteReceta[]>();
    const detallesDescuento: Array<{
      ingredienteNombre: string;
      inventarioItemId: number;
      cantidad: number;
      unidad: string;
    }> = [];

    for (const item of items) {
      const ingredientes = ingredientesMap.get(item.productoId) || [];
      const cantidadProducto = item.cantidad;
      const itemTamanoId = item.productoTamanoId ?? null;
      // Receta por tamaño: solo ingredientes del tamaño del ítem o sin tamaño (aplican a todos).
      for (const ingrediente of ingredientes) {
        if (ingrediente.productoTamanoId != null && !tamanoIdCoincide(ingrediente.productoTamanoId, itemTamanoId)) {
          continue;
        }
        if (ingrediente.descontarAutomaticamente && ingrediente.inventarioItemId) {
          const cantidadAporte = ingrediente.cantidadPorPorcion * cantidadProducto;
          const lista = aportesPorIngrediente.get(ingrediente.inventarioItemId) ?? [];
          lista.push({
            cantidad: cantidadAporte,
            unidad: (ingrediente.unidad || 'g').trim(),
            nombre: ingrediente.nombre
          });
          aportesPorIngrediente.set(ingrediente.inventarioItemId, lista);
          detallesDescuento.push({
            ingredienteNombre: ingrediente.nombre,
            inventarioItemId: ingrediente.inventarioItemId,
            cantidad: cantidadAporte,
            unidad: ingrediente.unidad
          });
        }
      }
    }

    if (aportesPorIngrediente.size === 0) {
      logger.info({ ordenId }, '📦 No hay ingredientes con descuento automático configurado');
      return;
    }

    // Descontar: convertir cada aporte a la unidad del inventario y sumar
    for (const [inventarioItemId, aportes] of aportesPorIngrediente.entries()) {
      try {
        const itemInventario = await obtenerInsumoPorId(inventarioItemId);
        if (!itemInventario) {
          logger.warn({ inventarioItemId, ordenId }, '⚠️ Item de inventario no encontrado para descuento');
          continue;
        }

        const unidadInventario = itemInventario.unidad.trim();
        let cantidadADescontar = 0;

        for (const aporte of aportes) {
          const convertida = cantidadEnUnidadInventario(aporte.cantidad, aporte.unidad, itemInventario);
          if (convertida === null) {
            logger.warn({
              inventarioItemId,
              ordenId,
              ingredienteNombre: aporte.nombre,
              unidadReceta: aporte.unidad,
              unidadInventario: itemInventario.unidad,
              itemNombre: itemInventario.nombre
            }, `⚠️ Unidades no compatibles para "${itemInventario.nombre}": receta usa "${aporte.unidad}", inventario usa "${itemInventario.unidad}". Omitiendo este aporte.`);
            continue;
          }
          cantidadADescontar += convertida;
        }

        if (cantidadADescontar <= 0) {
          logger.info({ inventarioItemId, ordenId }, '📦 No hubo cantidad a descontar (conversiones omitidas)');
          continue;
        }

        cantidadADescontar = redondearCantidad(cantidadADescontar);
        if (!Number.isFinite(cantidadADescontar) || cantidadADescontar <= 0) {
          logger.warn({ inventarioItemId, ordenId, cantidadADescontar }, '📦 Cantidad a descontar inválida, omitiendo');
          continue;
        }

        if (itemInventario.cantidadActual < cantidadADescontar) {
          logger.warn({
            inventarioItemId,
            ordenId,
            stockDisponible: itemInventario.cantidadActual,
            cantidadRequerida: cantidadADescontar,
            itemNombre: itemInventario.nombre,
            unidad: itemInventario.unidad
          }, `⚠️ Stock insuficiente para "${itemInventario.nombre}": disponible ${itemInventario.cantidadActual} ${itemInventario.unidad}, requerido ${cantidadADescontar} ${itemInventario.unidad}. Se establecerá en 0.`);
        }

        await registrarMovimiento({
          inventarioItemId,
          tipo: 'salida',
          cantidad: cantidadADescontar,
          costoUnitario: itemInventario.costoUnitario,
          motivo: `Descuento automático por preparación de orden ${ordenId}`,
          origen: 'consumo', // ENUM en BD: compra|consumo|ajuste|devolucion
          referenciaOrdenId: ordenId,
          usuarioId: usuarioId ?? null
        });
        
        // Obtener el item actualizado después del descuento
        const itemActualizado = await obtenerInsumoPorId(inventarioItemId);
        if (itemActualizado) {
          // Emitir evento de socket para actualizar inventario en tiempo real
          const { emitInventoryUpdated } = await import('../../realtime/events.js');
          emitInventoryUpdated(itemActualizado);
          // Alerta de inventario si cruzó umbral (stock mínimo o sin stock)
          const cruzoMinimo =
            itemInventario.cantidadActual > itemInventario.stockMinimo &&
            itemActualizado.cantidadActual <= itemActualizado.stockMinimo;
          const cruzoSinStock =
            itemInventario.cantidadActual > 0 && itemActualizado.cantidadActual <= 0;
          if (cruzoMinimo || cruzoSinStock) {
            const { emitirAlertaInventario } = await import('../alertas/alertas.service.js');
            emitirAlertaInventario(
              {
                id: itemActualizado.id,
                nombre: itemActualizado.nombre,
                cantidadActual: itemActualizado.cantidadActual,
                stockMinimo: itemActualizado.stockMinimo,
                unidad: itemActualizado.unidad
              },
              usuarioId ?? undefined
            ).catch((err) =>
              logger.warn({ err, inventarioItemId }, 'No se pudo emitir alerta de inventario')
            );
          }
        }
        
        logger.info({
          inventarioItemId,
          ordenId,
          cantidad: cantidadADescontar,
          unidad: itemInventario.unidad,
          nuevoStock: itemActualizado?.cantidadActual ?? Math.max(0, itemInventario.cantidadActual - cantidadADescontar)
        }, `✅ Inventario descontado automáticamente: ${cantidadADescontar} ${itemInventario.unidad} de "${itemInventario.nombre}"`);
      } catch (error: any) {
        logger.error({
          err: error,
          inventarioItemId,
          ordenId
        }, '❌ Error al descontar inventario automáticamente');
      }
    }
    
    // Log resumen (incluye que se respetó el tamaño del ítem por receta)
    const resumen = detallesDescuento.map(d => 
      `${d.ingredienteNombre}: -${d.cantidad} ${d.unidad}`
    ).join(', ');
    
    logger.info({
      ordenId,
      totalIngredientes: detallesDescuento.length,
      resumen
    }, `📦 Descuento automático completado para orden ${ordenId} (receta por tamaño aplicada)`);
    
  } catch (error: any) {
    logger.error({
      err: error,
      ordenId
    }, '❌ Error en descuento automático de inventario por receta');
    // No re-lanzar el error para que no afecte la actualización del estado de la orden
  }
};

/**
 * Sincroniza inventario para órdenes que ya estaban en "listo" o "listo para recoger"
 * pero no se les descontó por el bug de origen. Solo descontará las que aún no tengan
 * movimiento con referencia_orden_id.
 */
export const sincronizarInventarioOrdenesListas = async (): Promise<{
  procesadas: number;
  omitidas: number;
  errores: number;
}> => {
  const { listarOrdenIdsEnEstadoListo } = await import('../ordenes/ordenes.repository.js');
  const ordenIds = await listarOrdenIdsEnEstadoListo();
  let procesadas = 0;
  let omitidas = 0;
  let errores = 0;

  for (const ordenId of ordenIds) {
    const yaTieneMovimiento = await existeMovimientoConReferenciaOrden(ordenId);
    if (yaTieneMovimiento) {
      omitidas++;
      logger.info({ ordenId }, '📦 Orden ya tenía descuento de inventario, omitiendo');
      continue;
    }
    try {
      await descontarInventarioPorReceta(ordenId);
      procesadas++;
    } catch (error: any) {
      errores++;
      logger.error({ err: error, ordenId }, '❌ Error al sincronizar inventario para orden');
    }
  }

  return { procesadas, omitidas, errores };
};
