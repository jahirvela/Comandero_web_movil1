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
  crearCategoriaInventario as crearCategoriaInventarioRepo,
  eliminarCategoriaInventario as eliminarCategoriaInventarioRepo,
  contarItemsActivosPorCategoria,
  renombrarCategoriaInventario as renombrarCategoriaInventarioRepo
} from './inventario.repository.js';
import type {
  ActualizarInsumoInput,
  CrearInsumoInput,
  CrearMovimientoInput
} from './inventario.schemas.js';
import type { LineaFormulacionInput } from './inventario.repository.js';
import { notFound, forbidden, conflict, badRequest } from '../../utils/http-error.js';

/** Valida componentes BOM: existencia, no formulados, sin duplicados ni auto-referencia. */
const validarLineasFormulacion = async (
  padreId: number | null,
  lineas: LineaFormulacionInput[]
): Promise<void> => {
  const seen = new Set<number>();
  for (const L of lineas) {
    const cid = L.componenteInventarioItemId;
    if (padreId !== null && cid === padreId) {
      throw badRequest('Un producto formulado no puede incluirse a sí mismo como componente.');
    }
    if (seen.has(cid)) {
      throw badRequest('Hay componentes duplicados en la formulación.');
    }
    seen.add(cid);
    const comp = await obtenerInsumoPorId(cid);
    if (!comp) {
      throw badRequest(`Componente de inventario no encontrado (id ${cid}).`);
    }
    if (comp.esFormulado) {
      throw badRequest(
        `«${comp.nombre}» es un producto formulado y no puede usarse como componente.`
      );
    }
  }
};
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
  const esFormulado = input.esFormulado ?? false;
  const lineasFormulacion = input.lineasFormulacion ?? [];
  if (esFormulado) {
    await validarLineasFormulacion(null, lineasFormulacion);
  }
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
    unidadContenido: input.unidadContenido ?? null,
    esFormulado,
    lineasFormulacion: esFormulado ? lineasFormulacion : undefined
  });
  return obtenerInsumo(id);
};

export const actualizarInsumoExistente = async (id: number, input: ActualizarInsumoInput) => {
  const existe = await obtenerInsumoPorId(id);
  if (!existe) {
    throw notFound('Insumo no encontrado');
  }

  let esFormuladoPatch = input.esFormulado;
  let lineasPatch = input.lineasFormulacion;

  if (input.esFormulado === false) {
    esFormuladoPatch = false;
    lineasPatch = [];
  }

  if (input.lineasFormulacion !== undefined && input.lineasFormulacion.length === 0) {
    esFormuladoPatch = false;
    lineasPatch = [];
  } else if (
    input.lineasFormulacion !== undefined &&
    input.lineasFormulacion.length > 0 &&
    input.esFormulado === undefined
  ) {
    esFormuladoPatch = true;
  }

  const mergedEsFormulado =
    esFormuladoPatch !== undefined ? esFormuladoPatch : existe.esFormulado;

  const lineasParaValidar: LineaFormulacionInput[] =
    lineasPatch !== undefined
      ? lineasPatch
      : mergedEsFormulado
        ? existe.lineasFormulacion.map((l) => ({
            componenteInventarioItemId: l.componenteInventarioItemId,
            cantidad: l.cantidad,
            unidad: l.unidad
          }))
        : [];

  if (mergedEsFormulado) {
    if (lineasParaValidar.length === 0) {
      throw badRequest('Un producto formulado debe tener al menos una línea de formulación.');
    }
    await validarLineasFormulacion(id, lineasParaValidar);
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
    unidadContenido: input.unidadContenido,
    ...(esFormuladoPatch !== undefined ? { esFormulado: esFormuladoPatch } : {}),
    ...(lineasPatch !== undefined ? { lineasFormulacion: lineasPatch } : {})
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

export const obtenerMovimientos = (opts?: {
  inventarioItemId?: number;
  desde?: Date;
  hasta?: Date;
  limit?: number;
}) => listarMovimientos(opts);

export const obtenerCategorias = async () => {
  const categorias = await obtenerCategoriasUnicas();
  return categorias;
};

/** Crea una categoría de inventario (persistida). Si ya existe (misma escritura, sin importar mayúsculas), created=false. */
export const crearCategoriaInventario = async (
  nombre: string
): Promise<{ categorias: string[]; created: boolean }> => {
  return crearCategoriaInventarioRepo(nombre);
};

export const eliminarCategoriaInventario = async (nombre: string): Promise<string[]> => {
  const n = nombre.trim();
  if (!n) return obtenerCategorias();
  if (n.toLowerCase() === 'todos') {
    throw forbidden('No se puede eliminar la categoría «Todos».');
  }
  const numItems = await contarItemsActivosPorCategoria(n);
  if (numItems > 0) {
    throw conflict(
      'No se puede eliminar la categoría porque tiene ítems de inventario asignados. Reasigne los ítems a otra categoría o elimínelos primero.'
    );
  }
  await eliminarCategoriaInventarioRepo(n);
  return obtenerCategorias();
};

export const renombrarCategoriaInventario = async (nombreActual: string, nombreNuevo: string) => {
  const v = nombreActual.trim();
  const n = nombreNuevo.trim();
  if (!v || !n) {
    throw badRequest('Indica el nombre actual y el nuevo nombre.');
  }
  if (v.toLowerCase() === 'todos' || n.toLowerCase() === 'todos') {
    throw forbidden('No se puede usar la categoría «Todos».');
  }
  try {
    await renombrarCategoriaInventarioRepo(v, n);
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : '';
    if (msg === 'CATEGORIA_NOT_FOUND') {
      throw notFound('Categoría no encontrada');
    }
    if (msg === 'CATEGORIA_DUPLICATE') {
      throw conflict('Ya existe una categoría con ese nombre');
    }
    if (msg === 'CATEGORIA_INVALID') {
      throw badRequest('Nombre inválido');
    }
    throw e;
  }
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

type AporteReceta = { cantidad: number; unidad: string; nombre: string };

/**
 * Formulados con BOM: expande a componentes y además deja un aporte del ítem padre
 * (cantidad ya en unidad de inventario del padre) para que también descuente la existencia
 * del producto formulado junto con las materias primas.
 */
const expandirAportesFormuladosABom = async (
  aportesPorIngrediente: Map<number, AporteReceta[]>
): Promise<Map<number, AporteReceta[]>> => {
  const out = new Map<number, AporteReceta[]>();

  const mergeInto = (id: number, nuevos: AporteReceta[]) => {
    const prev = out.get(id) ?? [];
    out.set(id, [...prev, ...nuevos]);
  };

  for (const [invId, aportes] of aportesPorIngrediente.entries()) {
    const item = await obtenerInsumoPorId(invId);
    if (!item?.esFormulado || !item.lineasFormulacion?.length) {
      mergeInto(invId, aportes);
      continue;
    }

    let cantidadPadre = 0;
    for (const a of aportes) {
      const c = cantidadEnUnidadInventario(a.cantidad, a.unidad, item);
      if (c != null && c > 0) cantidadPadre += c;
    }
    cantidadPadre = redondearCantidad(cantidadPadre);
    if (cantidadPadre <= 0) continue;

    mergeInto(invId, [
      {
        cantidad: cantidadPadre,
        unidad: item.unidad.trim(),
        nombre: item.nombre
      }
    ]);

    for (const line of item.lineasFormulacion) {
      const comp = await obtenerInsumoPorId(line.componenteInventarioItemId);
      if (!comp) continue;
      const qtyEnUnidadLineaBom = cantidadPadre * line.cantidad;
      const convertida = cantidadEnUnidadInventario(
        qtyEnUnidadLineaBom,
        line.unidad.trim(),
        comp
      );
      if (convertida == null || convertida <= 0) continue;
      mergeInto(comp.id, [
        {
          cantidad: redondearCantidad(convertida),
          unidad: comp.unidad.trim(),
          nombre: line.nombreComponente || comp.nombre
        }
      ]);
    }
  }

  return out;
};

const notificarInventarioTrasSalidaPorOrden = async (
  inventarioItemId: number,
  itemAntes: { cantidadActual: number; stockMinimo: number },
  usuarioId?: number
) => {
  const itemActualizado = await obtenerInsumoPorId(inventarioItemId);
  if (!itemActualizado) return undefined;
  const { emitInventoryUpdated } = await import('../../realtime/events.js');
  emitInventoryUpdated(itemActualizado);
  const cruzoMinimo =
    itemAntes.cantidadActual > itemAntes.stockMinimo &&
    itemActualizado.cantidadActual <= itemActualizado.stockMinimo;
  const cruzoSinStock =
    itemAntes.cantidadActual > 0 && itemActualizado.cantidadActual <= 0;
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
  return itemActualizado;
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

    const aportesExpandidos = await expandirAportesFormuladosABom(aportesPorIngrediente);

    for (const [inventarioItemId, aportes] of aportesExpandidos.entries()) {
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

    const aportesExpandidos = await expandirAportesFormuladosABom(aportesPorIngrediente);

    // Descontar: convertir cada aporte a la unidad del inventario y sumar
    for (const [inventarioItemId, aportes] of aportesExpandidos.entries()) {
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

        const itemActualizado = await notificarInventarioTrasSalidaPorOrden(
          inventarioItemId,
          itemInventario,
          usuarioId
        );

        logger.info({
          inventarioItemId,
          ordenId,
          cantidad: cantidadADescontar,
          unidad: itemInventario.unidad,
          nuevoStock:
            itemActualizado?.cantidadActual ??
            Math.max(0, itemInventario.cantidadActual - cantidadADescontar)
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
