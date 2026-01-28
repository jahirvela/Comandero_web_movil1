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
import { logger } from '../../config/logger.js';

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

/**
 * Convierte una cantidad de una unidad a otra unidad compatible
 * @param cantidad Cantidad a convertir
 * @param unidadOrigen Unidad de origen (ej: "g", "kg", "ml", "L")
 * @param unidadDestino Unidad de destino (ej: "kg", "g", "L", "ml")
 * @returns Cantidad convertida o null si las unidades no son compatibles
 */
const convertirUnidad = (
  cantidad: number,
  unidadOrigen: string,
  unidadDestino: string
): number | null => {
  const unidadOrigenLower = unidadOrigen.toLowerCase().trim();
  const unidadDestinoLower = unidadDestino.toLowerCase().trim();
  
  // Si las unidades son iguales, no hay conversión
  if (unidadOrigenLower === unidadDestinoLower) {
    return cantidad;
  }
  
  // Conversiones de peso: kg <-> g
  if ((unidadOrigenLower === 'kg' || unidadOrigenLower === 'kilogramo' || unidadOrigenLower === 'kilogramos') &&
      (unidadDestinoLower === 'g' || unidadDestinoLower === 'gramo' || unidadDestinoLower === 'gramos')) {
    return cantidad * 1000; // 1 kg = 1000 g
  }
  if ((unidadOrigenLower === 'g' || unidadOrigenLower === 'gramo' || unidadOrigenLower === 'gramos') &&
      (unidadDestinoLower === 'kg' || unidadDestinoLower === 'kilogramo' || unidadDestinoLower === 'kilogramos')) {
    return cantidad / 1000; // 1 g = 0.001 kg
  }
  
  // Conversiones de volumen: L <-> ml
  if ((unidadOrigenLower === 'l' || unidadOrigenLower === 'litro' || unidadOrigenLower === 'litros') &&
      (unidadDestinoLower === 'ml' || unidadDestinoLower === 'mililitro' || unidadDestinoLower === 'mililitros')) {
    return cantidad * 1000; // 1 L = 1000 ml
  }
  if ((unidadOrigenLower === 'ml' || unidadOrigenLower === 'mililitro' || unidadOrigenLower === 'mililitros') &&
      (unidadDestinoLower === 'l' || unidadDestinoLower === 'litro' || unidadDestinoLower === 'litros')) {
    return cantidad / 1000; // 1 ml = 0.001 L
  }
  
  // Si no hay conversión compatible, retornar null
  return null;
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
    
    // Acumular descuentos por ingrediente
    const descuentosPorIngrediente = new Map<number, number>(); // Map<inventarioItemId, cantidadTotal>
    const unidadesPorIngrediente = new Map<number, string>(); // Map<inventarioItemId, unidad>
    const nombresPorIngrediente = new Map<number, string>(); // Map<inventarioItemId, nombre>
    const detallesDescuento: Array<{
      ingredienteNombre: string;
      inventarioItemId: number;
      cantidad: number;
      unidad: string;
    }> = [];
    
    // Procesar cada item de la orden
    for (const item of items) {
      const ingredientes = ingredientesMap.get(item.productoId) || [];
      const cantidadProducto = item.cantidad;
      const itemTamanoId = item.productoTamanoId ?? null;
      
      // Procesar cada ingrediente de la receta
      for (const ingrediente of ingredientes) {
        // Si el ingrediente está ligado a un tamaño, solo aplica a ese tamaño
        if (
          ingrediente.productoTamanoId != null &&
          ingrediente.productoTamanoId !== itemTamanoId
        ) {
          continue;
        }
        // Solo descontar si tiene autoDeduct activado y tiene inventarioItemId
        // Nota: Se descuentan TODOS los ingredientes con autoDeduct, incluso los opcionales,
        // ya que el inventario es estimado y es más práctico descontar todo automáticamente
        if (ingrediente.descontarAutomaticamente && ingrediente.inventarioItemId) {
          const cantidadADescontar = ingrediente.cantidadPorPorcion * cantidadProducto;
          
          // Acumular descuento (la validación de unidades se hará después)
          const cantidadActual = descuentosPorIngrediente.get(ingrediente.inventarioItemId) || 0;
          descuentosPorIngrediente.set(
            ingrediente.inventarioItemId,
            cantidadActual + cantidadADescontar
          );
          
          // Guardar unidad y nombre del ingrediente (solo la primera vez)
          if (!unidadesPorIngrediente.has(ingrediente.inventarioItemId)) {
            unidadesPorIngrediente.set(ingrediente.inventarioItemId, ingrediente.unidad);
            nombresPorIngrediente.set(ingrediente.inventarioItemId, ingrediente.nombre);
          }
          
          // Guardar detalle para logging (incluyendo información de unidad)
          detallesDescuento.push({
            ingredienteNombre: ingrediente.nombre,
            inventarioItemId: ingrediente.inventarioItemId,
            cantidad: cantidadADescontar,
            unidad: ingrediente.unidad
          });
        }
      }
    }
    
    // Si no hay descuentos, no hacer nada
    if (descuentosPorIngrediente.size === 0) {
      logger.info({ ordenId }, '📦 No hay ingredientes con descuento automático configurado');
      return;
    }
    
    // Realizar descuentos en el inventario
    for (const [inventarioItemId, cantidadTotal] of descuentosPorIngrediente.entries()) {
      try {
        // Verificar que el item de inventario existe
        const itemInventario = await obtenerInsumoPorId(inventarioItemId);
        if (!itemInventario) {
          logger.warn({ inventarioItemId, ordenId }, '⚠️ Item de inventario no encontrado para descuento');
          continue;
        }
        
        // Validar y convertir unidades si es necesario
        const unidadIngrediente = unidadesPorIngrediente.get(inventarioItemId);
        const nombreIngrediente = nombresPorIngrediente.get(inventarioItemId) || itemInventario.nombre;
        let cantidadADescontar = cantidadTotal;
        
        if (unidadIngrediente) {
          const unidadIngredienteLower = unidadIngrediente.toLowerCase();
          const unidadInventarioLower = itemInventario.unidad.toLowerCase();
          
          // Si las unidades no coinciden, intentar convertir
          if (unidadIngredienteLower !== unidadInventarioLower) {
            const cantidadConvertida = convertirUnidad(
              cantidadTotal,
              unidadIngrediente,
              itemInventario.unidad
            );
            
            if (cantidadConvertida === null) {
              // No hay conversión compatible
              logger.warn({
                inventarioItemId,
                ordenId,
                ingredienteNombre: nombreIngrediente,
                unidadIngrediente: unidadIngrediente,
                unidadInventario: itemInventario.unidad,
                itemNombre: itemInventario.nombre
              }, `⚠️ Unidades no compatibles para "${itemInventario.nombre}": receta usa "${unidadIngrediente}" pero inventario usa "${itemInventario.unidad}". No se puede convertir. Omitiendo descuento.`);
              continue;
            }
            
            // Usar la cantidad convertida
            cantidadADescontar = cantidadConvertida;
            logger.info({
              inventarioItemId,
              ordenId,
              ingredienteNombre: nombreIngrediente,
              unidadIngrediente: unidadIngrediente,
              unidadInventario: itemInventario.unidad,
              cantidadOriginal: cantidadTotal,
              cantidadConvertida: cantidadADescontar,
              itemNombre: itemInventario.nombre
            }, `🔄 Convertido ${cantidadTotal} ${unidadIngrediente} a ${cantidadADescontar} ${itemInventario.unidad} para "${itemInventario.nombre}"`);
          }
        }
        
        // Verificar stock disponible (solo para logging, se establecerá en 0 si es insuficiente)
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
        
        // Registrar movimiento de salida (usando la cantidad convertida)
        await registrarMovimiento({
          inventarioItemId,
          tipo: 'salida',
          cantidad: cantidadADescontar,
          costoUnitario: itemInventario.costoUnitario,
          motivo: `Descuento automático por preparación de orden ${ordenId}`,
          origen: 'receta_automatica',
          referenciaOrdenId: ordenId,
          usuarioId: usuarioId ?? null
        });
        
        // Obtener el item actualizado después del descuento
        const itemActualizado = await obtenerInsumoPorId(inventarioItemId);
        if (itemActualizado) {
          // Emitir evento de socket para actualizar inventario en tiempo real
          const { emitInventoryUpdated } = await import('../../realtime/events.js');
          emitInventoryUpdated(itemActualizado);
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
          ordenId,
          cantidad: cantidadTotal
        }, '❌ Error al descontar inventario automáticamente');
        // Continuar con el siguiente ingrediente aunque falle uno
      }
    }
    
    // Log resumen
    const resumen = detallesDescuento.map(d => 
      `${d.ingredienteNombre}: -${d.cantidad} ${d.unidad}`
    ).join(', ');
    
    logger.info({
      ordenId,
      totalIngredientes: detallesDescuento.length,
      resumen
    }, `📦 Descuento automático completado para orden ${ordenId}`);
    
  } catch (error: any) {
    logger.error({
      err: error,
      ordenId
    }, '❌ Error en descuento automático de inventario por receta');
    // No re-lanzar el error para que no afecte la actualización del estado de la orden
  }
};

