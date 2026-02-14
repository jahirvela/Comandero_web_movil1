import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool, withTransaction } from '../../db/pool.js';
import { utcToMxISO } from '../../config/time.js';

interface InventarioItemRow extends RowDataPacket {
  id: number;
  nombre: string;
  codigo_barras?: string | null;
  categoria: string | null;
  unidad: string;
  cantidad_actual: number;
  stock_minimo: number;
  stock_maximo: number | null;
  costo_unitario: number | null;
  proveedor: string | null;
  activo: number;
  contenido_por_pieza?: number | null;
  unidad_contenido?: string | null;
  creado_en: Date;
  actualizado_en: Date;
}

interface MovimientoRow extends RowDataPacket {
  id: number;
  inventario_item_id: number;
  tipo: string;
  cantidad: number;
  costo_unitario: number | null;
  motivo: string | null;
  origen: string | null;
  referencia_orden_id: number | null;
  creado_por_usuario_id: number | null;
  creado_en: Date;
  item_nombre: string;
  unidad: string;
}

export const listarInsumos = async () => {
  await ensureCodigoBarrasColumnExists();
  await ensureContenidoPorPiezaColumnsExist();
  try {
    const [rows] = await pool.query<InventarioItemRow[]>(
      `
      SELECT *
      FROM inventario_item
      WHERE activo = 1
      ORDER BY categoria, nombre
      `
    );

    return rows.map((row) => ({
      id: row.id,
      nombre: row.nombre,
      codigoBarras: (row as InventarioItemRow).codigo_barras ?? null,
      categoria: row.categoria ?? '',
      unidad: row.unidad,
      cantidadActual: Number(row.cantidad_actual),
      stockMinimo: Number(row.stock_minimo),
      stockMaximo: row.stock_maximo === null ? null : Number(row.stock_maximo),
      costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
      proveedor: row.proveedor ?? null,
      activo: Boolean(row.activo),
      contenidoPorPieza: (row as InventarioItemRow).contenido_por_pieza == null ? null : Number((row as InventarioItemRow).contenido_por_pieza),
      unidadContenido: (row as InventarioItemRow).unidad_contenido ?? null,
      creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null),
      actualizadoEn: utcToMxISO(row.actualizado_en) ?? (row.actualizado_en != null ? (row.actualizado_en as Date).toISOString() : null)
    }));
  } catch (error: any) {
    // Si la columna no existe, intentar sin ordenar por categoria
    if (error.code === 'ER_BAD_FIELD_ERROR' || error.message?.includes('Unknown column')) {
      const [rows] = await pool.query<InventarioItemRow[]>(
        `
        SELECT id, nombre, unidad, cantidad_actual, stock_minimo, costo_unitario, activo, creado_en, actualizado_en
        FROM inventario_item
        WHERE activo = 1
        ORDER BY nombre
        `
      );
      return rows.map((row) => ({
        id: row.id,
        nombre: row.nombre,
        codigoBarras: null,
        categoria: '',
        unidad: row.unidad,
        cantidadActual: Number(row.cantidad_actual),
        stockMinimo: Number(row.stock_minimo),
        stockMaximo: (row as any).stock_maximo === null ? null : Number((row as any).stock_maximo),
        costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
        proveedor: (row as any).proveedor ?? null,
        activo: Boolean(row.activo),
        contenidoPorPieza: (row as any).contenido_por_pieza == null ? null : Number((row as any).contenido_por_pieza),
        unidadContenido: (row as any).unidad_contenido ?? null,
        creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null),
        actualizadoEn: utcToMxISO(row.actualizado_en) ?? (row.actualizado_en != null ? (row.actualizado_en as Date).toISOString() : null)
      }));
    }
    throw error;
  }
};

export const obtenerInsumoPorId = async (id: number) => {
  await ensureContenidoPorPiezaColumnsExist();
  const [rows] = await pool.query<InventarioItemRow[]>(
    `
    SELECT *
    FROM inventario_item
    WHERE id = :id
    `,
    { id }
  );
  const row = rows[0];
  if (!row) return null;
  return {
    id: row.id,
    nombre: row.nombre,
    codigoBarras: (row as InventarioItemRow).codigo_barras ?? null,
    categoria: row.categoria ?? '',
    unidad: row.unidad,
    cantidadActual: Number(row.cantidad_actual),
    stockMinimo: Number(row.stock_minimo),
    stockMaximo: row.stock_maximo === null ? null : Number(row.stock_maximo),
    costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
    proveedor: row.proveedor ?? null,
    activo: Boolean(row.activo),
    contenidoPorPieza: (row as InventarioItemRow).contenido_por_pieza == null ? null : Number((row as InventarioItemRow).contenido_por_pieza),
    unidadContenido: (row as InventarioItemRow).unidad_contenido ?? null,
    creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null),
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? (row.actualizado_en != null ? (row.actualizado_en as Date).toISOString() : null)
  };
};

/** Obtiene un ítem de inventario por su código de barras (único por línea de producto). */
export const obtenerInsumoPorCodigoBarras = async (codigoBarras: string) => {
  const codigo = String(codigoBarras).trim();
  if (!codigo) return null;
  await ensureCodigoBarrasColumnExists();
  await ensureContenidoPorPiezaColumnsExist();
  const [rows] = await pool.query<InventarioItemRow[]>(
    `
    SELECT *
    FROM inventario_item
    WHERE BINARY codigo_barras = :codigo AND activo = 1
    LIMIT 1
    `,
    { codigo }
  );
  const row = rows[0];
  if (!row) return null;
  return {
    id: row.id,
    nombre: row.nombre,
    codigoBarras: (row as InventarioItemRow).codigo_barras ?? null,
    categoria: row.categoria ?? '',
    unidad: row.unidad,
    cantidadActual: Number(row.cantidad_actual),
    stockMinimo: Number(row.stock_minimo),
    stockMaximo: row.stock_maximo === null ? null : Number(row.stock_maximo),
    costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
    proveedor: row.proveedor ?? null,
    activo: Boolean(row.activo),
    contenidoPorPieza: (row as InventarioItemRow).contenido_por_pieza == null ? null : Number((row as InventarioItemRow).contenido_por_pieza),
    unidadContenido: (row as InventarioItemRow).unidad_contenido ?? null,
    creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null),
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? (row.actualizado_en != null ? (row.actualizado_en as Date).toISOString() : null)
  };
};

// Función auxiliar para verificar y crear la columna categoria si no existe
const ensureCategoriaColumnExists = async () => {
  try {
    const [columns] = await pool.query(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'categoria'
      `
    );

    if ((columns as Array<{ COLUMN_NAME: string }>).length === 0) {
      // La columna no existe, crearla
      await pool.execute(
        `
        ALTER TABLE inventario_item
        ADD COLUMN categoria VARCHAR(64) NOT NULL DEFAULT 'Otros'
        `
      );
      console.log('✓ Columna categoria creada automáticamente en inventario_item');
    }
  } catch (error: any) {
    // Si falla la verificación/creación, solo loguear el error pero no fallar
    console.warn('Advertencia: No se pudo verificar/crear la columna categoria:', error.message);
  }
};

// Función auxiliar para verificar y crear la columna proveedor si no existe
const ensureProveedorColumnExists = async () => {
  try {
    const [columns] = await pool.query(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'proveedor'
      `
    );

    if ((columns as Array<{ COLUMN_NAME: string }>).length === 0) {
      // La columna no existe, crearla
      await pool.execute(
        `
        ALTER TABLE inventario_item
        ADD COLUMN proveedor VARCHAR(120) NULL
        `
      );
      console.log('✓ Columna proveedor creada automáticamente en inventario_item');
    }
  } catch (error: any) {
    // Si falla la verificación/creación, solo loguear el error pero no fallar
    console.warn('Advertencia: No se pudo verificar/crear la columna proveedor:', error.message);
  }
};

// Función auxiliar para verificar y crear la columna stock_maximo si no existe
const ensureStockMaximoColumnExists = async () => {
  try {
    const [columns] = await pool.query(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'stock_maximo'
      `
    );

    if ((columns as Array<{ COLUMN_NAME: string }>).length === 0) {
      // La columna no existe, crearla
      await pool.execute(
        `
        ALTER TABLE inventario_item
        ADD COLUMN stock_maximo DECIMAL(10,2) NULL
        `
      );
      console.log('✓ Columna stock_maximo creada automáticamente en inventario_item');
    }
  } catch (error: any) {
    // Si falla la verificación/creación, solo loguear el error pero no fallar
    console.warn('Advertencia: No se pudo verificar/crear la columna stock_maximo:', error.message);
  }
};

const ensureCodigoBarrasColumnExists = async () => {
  try {
    const [columns] = await pool.query(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'codigo_barras'
      `
    );
    if ((columns as Array<{ COLUMN_NAME: string }>).length === 0) {
      await pool.execute(
        `
        ALTER TABLE inventario_item
        ADD COLUMN codigo_barras VARCHAR(64) NULL UNIQUE
        COMMENT 'Código de barras único por línea de producto'
        AFTER nombre
        `
      );
      console.log('✓ Columna codigo_barras creada automáticamente en inventario_item');
    }
  } catch (error: any) {
    console.warn('Advertencia: No se pudo verificar/crear la columna codigo_barras:', error.message);
  }
};

/** Crea columnas contenido_por_pieza y unidad_contenido si no existen (productos por pieza con equivalencia en kg/L). */
const ensureContenidoPorPiezaColumnsExist = async () => {
  try {
    const [columns] = await pool.query(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'contenido_por_pieza'
      `
    );
    if ((columns as Array<{ COLUMN_NAME: string }>).length === 0) {
      await pool.execute(
        `ALTER TABLE inventario_item ADD COLUMN contenido_por_pieza DECIMAL(12,4) NULL COMMENT 'Peso o volumen por pieza (ej. 5 para envase 5 kg)' AFTER activo`
      );
      await pool.execute(
        `ALTER TABLE inventario_item ADD COLUMN unidad_contenido VARCHAR(16) NULL COMMENT 'Unidad del contenido (kg, g, L, ml)' AFTER contenido_por_pieza`
      );
      console.log('✓ Columnas contenido_por_pieza y unidad_contenido creadas en inventario_item');
    }
  } catch (error: any) {
    console.warn('Advertencia: No se pudo verificar/crear columnas contenido_por_pieza:', (error as Error).message);
  }
};

export const crearInsumo = async ({
  nombre,
  codigoBarras,
  categoria,
  unidad,
  cantidadActual,
  stockMinimo,
  stockMaximo,
  costoUnitario,
  proveedor,
  activo,
  contenidoPorPieza,
  unidadContenido
}: {
  nombre: string;
  codigoBarras?: string | null;
  categoria: string;
  unidad: string;
  cantidadActual: number;
  stockMinimo: number;
  stockMaximo?: number | null;
  costoUnitario?: number | null;
  proveedor?: string | null;
  activo: boolean;
  contenidoPorPieza?: number | null;
  unidadContenido?: string | null;
}) => {
  try {
    await ensureCategoriaColumnExists();
    await ensureProveedorColumnExists();
    await ensureStockMaximoColumnExists();
    await ensureCodigoBarrasColumnExists();
    await ensureContenidoPorPiezaColumnsExist();
    
    // Usar transacción para eliminar duplicados y crear nuevo registro de forma atómica
    return await withTransaction(async (conn) => {
      // Primero, eliminar cualquier registro existente con el mismo nombre (activo o inactivo)
      // Esto evita problemas con el constraint único ux_inventario_nombre
      try {
        // Obtener IDs de registros existentes con ese nombre
        const [existingRows] = await conn.query(
          `SELECT id FROM inventario_item WHERE nombre = :nombre`,
          { nombre }
        );
        
        const existingArr = existingRows as Array<{ id: number }>;
        if (existingArr.length > 0) {
          const existingIds = existingArr.map(row => row.id);
          console.log(`⚠️ Encontrados ${existingIds.length} registro(s) existente(s) con el nombre "${nombre}". Eliminando antes de crear uno nuevo.`);
          
          // Eliminar referencias en producto_ingrediente
          for (const id of existingIds) {
            try {
              await conn.execute(
                `DELETE FROM producto_ingrediente WHERE inventario_item_id = :id`,
                { id }
              );
            } catch (error: any) {
              // Si la tabla no existe o hay error, continuar
              console.warn(`Advertencia: No se pudo eliminar referencias en producto_ingrediente para item ${id}:`, error.message);
            }
          }
          
          // Eliminar referencias en movimiento_inventario
          for (const id of existingIds) {
            try {
              await conn.execute(
                `DELETE FROM movimiento_inventario WHERE inventario_item_id = :id`,
                { id }
              );
            } catch (error: any) {
              console.warn(`Advertencia: No se pudo eliminar referencias en movimiento_inventario para item ${id}:`, error.message);
            }
          }
          
          // Finalmente eliminar los registros del inventario
          for (const id of existingIds) {
            await conn.execute(
              `DELETE FROM inventario_item WHERE id = :id`,
              { id }
            );
          }
          
          console.log(`✅ Registro(s) duplicado(s) eliminado(s) correctamente. Procediendo a crear nuevo registro.`);
        }
      } catch (error: any) {
        // Si hay error al eliminar duplicados, registrar pero continuar
        console.warn(`Advertencia al eliminar registros duplicados:`, error.message);
      }
      
      const [result] = await conn.execute<ResultSetHeader>(
      `
      INSERT INTO inventario_item (nombre, codigo_barras, categoria, unidad, cantidad_actual, stock_minimo, stock_maximo, costo_unitario, proveedor, activo, contenido_por_pieza, unidad_contenido)
      VALUES (:nombre, :codigoBarras, :categoria, :unidad, :cantidadActual, :stockMinimo, :stockMaximo, :costoUnitario, :proveedor, :activo, :contenidoPorPieza, :unidadContenido)
      `,
      {
        nombre,
        codigoBarras: codigoBarras?.trim() || null,
        categoria,
        unidad,
        cantidadActual,
        stockMinimo,
        stockMaximo: stockMaximo ?? null,
        costoUnitario: costoUnitario ?? null,
        proveedor: proveedor ?? null,
        activo: activo ? 1 : 0,
        contenidoPorPieza: contenidoPorPieza ?? null,
        unidadContenido: unidadContenido?.trim() || null
      }
      );
      return result.insertId;
    });
  } catch (error: any) {
    // Si la columna no existe después de intentar crearla, dar un error más claro
    if (error.code === 'ER_BAD_FIELD_ERROR' || error.message?.includes('Unknown column')) {
      throw new Error('La columna categoria, proveedor o stock_maximo no existe en la base de datos. Por favor ejecuta: npm run migrate:inventory-category en el backend');
    }
    throw error;
  }
};

export const actualizarInsumo = async (
  id: number,
  {
    nombre,
    codigoBarras,
    categoria,
    unidad,
    cantidadActual,
    stockMinimo,
    stockMaximo,
    costoUnitario,
    proveedor,
    activo,
    contenidoPorPieza,
    unidadContenido
  }: {
    nombre?: string;
    codigoBarras?: string | null;
    categoria?: string;
    unidad?: string;
    cantidadActual?: number;
    stockMinimo?: number;
    stockMaximo?: number | null;
    costoUnitario?: number | null;
    proveedor?: string | null;
    activo?: boolean;
    contenidoPorPieza?: number | null;
    unidadContenido?: string | null;
  }
) => {
  if (categoria !== undefined) await ensureCategoriaColumnExists();
  if (proveedor !== undefined) await ensureProveedorColumnExists();
  if (stockMaximo !== undefined) await ensureStockMaximoColumnExists();
  if (codigoBarras !== undefined) await ensureCodigoBarrasColumnExists();
  if (contenidoPorPieza !== undefined || unidadContenido !== undefined) await ensureContenidoPorPiezaColumnsExist();
  const fields: string[] = [];
  const params: Record<string, unknown> = { id };

  if (nombre !== undefined) {
    fields.push('nombre = :nombre');
    params.nombre = nombre;
  }
  if (codigoBarras !== undefined) {
    fields.push('codigo_barras = :codigoBarras');
    params.codigoBarras = codigoBarras?.trim() || null;
  }
  if (categoria !== undefined) {
    fields.push('categoria = :categoria');
    params.categoria = categoria;
  }
  if (unidad !== undefined) {
    fields.push('unidad = :unidad');
    params.unidad = unidad;
  }
  if (cantidadActual !== undefined) {
    fields.push('cantidad_actual = :cantidadActual');
    params.cantidadActual = cantidadActual;
  }
  if (stockMinimo !== undefined) {
    fields.push('stock_minimo = :stockMinimo');
    params.stockMinimo = stockMinimo;
  }
  if (stockMaximo !== undefined) {
    fields.push('stock_maximo = :stockMaximo');
    params.stockMaximo = stockMaximo ?? null;
  }
  if (costoUnitario !== undefined) {
    fields.push('costo_unitario = :costoUnitario');
    params.costoUnitario = costoUnitario ?? null;
  }
  if (proveedor !== undefined) {
    fields.push('proveedor = :proveedor');
    params.proveedor = proveedor ?? null;
  }
  if (activo !== undefined) {
    fields.push('activo = :activo');
    params.activo = activo ? 1 : 0;
  }
  if (contenidoPorPieza !== undefined) {
    fields.push('contenido_por_pieza = :contenidoPorPieza');
    params.contenidoPorPieza = contenidoPorPieza ?? null;
  }
  if (unidadContenido !== undefined) {
    fields.push('unidad_contenido = :unidadContenido');
    params.unidadContenido = unidadContenido?.trim() || null;
  }

  if (fields.length === 0) return;

  await pool.execute(
    `
    UPDATE inventario_item
    SET ${fields.join(', ')}, actualizado_en = NOW()
    WHERE id = :id
    `,
    params
  );
};

export const desactivarInsumo = async (id: number) => {
  // Eliminar físicamente el registro para permitir recrear con el mismo nombre
  // Primero eliminar referencias en movimiento_inventario
  await pool.execute(
    `
    DELETE FROM movimiento_inventario
    WHERE inventario_item_id = :id
    `,
    { id }
  );
  
  // Eliminar referencias en producto_ingrediente (si existe la tabla)
  try {
    const [deleteResult] = await pool.execute<ResultSetHeader>(
      `
      DELETE FROM producto_ingrediente
      WHERE inventario_item_id = :id
      `,
      { id }
    );
    const deletedCount = deleteResult.affectedRows;
    if (deletedCount > 0) {
      console.log(`✅ Se eliminaron ${deletedCount} ingrediente(s) de las recetas que usaban este item del inventario`);
    }
  } catch (error: any) {
    // Si la tabla no existe o hay error, continuar
    console.warn('Error al eliminar referencias en producto_ingrediente:', error.message);
  }
  
  // Finalmente eliminar el registro del inventario
  await pool.execute(
    `
    DELETE FROM inventario_item
    WHERE id = :id
    `,
    { id }
  );
};

export const registrarMovimiento = async ({
  inventarioItemId,
  tipo,
  cantidad,
  costoUnitario,
  motivo,
  origen,
  referenciaOrdenId,
  usuarioId
}: {
  inventarioItemId: number;
  tipo: 'entrada' | 'salida' | 'ajuste';
  cantidad: number;
  costoUnitario?: number | null;
  motivo?: string | null;
  origen?: string | null;
  referenciaOrdenId?: number | null;
  usuarioId?: number | null;
}) => {
  await withTransaction(async (conn) => {
    const signo = tipo === 'salida' ? -1 : tipo === 'entrada' ? 1 : 0;

    let nuevaCantidad: number | null = null;

    if (tipo === 'ajuste') {
      nuevaCantidad = cantidad;
      await conn.execute(
        `
        UPDATE inventario_item
        SET cantidad_actual = :nuevaCantidad, actualizado_en = NOW()
        WHERE id = :inventarioItemId
        `,
        { nuevaCantidad, inventarioItemId }
      );
    } else {
      // Para salidas, asegurar que el stock no sea negativo (establecer en 0 si sería negativo)
      if (tipo === 'salida') {
        await conn.execute(
          `
          UPDATE inventario_item
          SET cantidad_actual = GREATEST(0, cantidad_actual - :cantidad), actualizado_en = NOW()
          WHERE id = :inventarioItemId
          `,
          { inventarioItemId, cantidad }
        );
      } else {
        // Para entradas, suma normal
        await conn.execute(
          `
          UPDATE inventario_item
          SET cantidad_actual = cantidad_actual + :cantidad, actualizado_en = NOW()
          WHERE id = :inventarioItemId
          `,
          { inventarioItemId, cantidad }
        );
      }
    }

    await conn.execute(
      `
      INSERT INTO movimiento_inventario (
        inventario_item_id,
        tipo,
        cantidad,
        costo_unitario,
        motivo,
        origen,
        referencia_orden_id,
        creado_por_usuario_id
      )
      VALUES (
        :inventarioItemId,
        :tipo,
        :cantidadRegistro,
        :costoUnitario,
        :motivo,
        :origen,
        :referenciaOrdenId,
        :usuarioId
      )
      `,
      {
        inventarioItemId,
        tipo,
        cantidadRegistro: tipo === 'ajuste' ? cantidad : signo * cantidad,
        costoUnitario: costoUnitario ?? null,
        motivo: motivo ?? null,
        origen: origen ?? null,
        referenciaOrdenId: referenciaOrdenId ?? null,
        usuarioId: usuarioId ?? null
      }
    );
  });
};

/**
 * Indica si ya existe al menos un movimiento de inventario con referencia a esta orden
 * (evita descontar dos veces la misma orden al sincronizar).
 */
export const existeMovimientoConReferenciaOrden = async (ordenId: number): Promise<boolean> => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT 1 FROM movimiento_inventario WHERE referencia_orden_id = :ordenId LIMIT 1`,
    { ordenId }
  );
  return Array.isArray(rows) && rows.length > 0;
};

export const listarMovimientos = async (inventarioItemId?: number) => {
  const [rows] = await pool.query<MovimientoRow[]>(
    `
    SELECT
      m.*,
      i.nombre AS item_nombre,
      i.unidad
    FROM movimiento_inventario m
    JOIN inventario_item i ON i.id = m.inventario_item_id
    ${inventarioItemId ? 'WHERE m.inventario_item_id = :inventarioItemId' : ''}
    ORDER BY m.creado_en DESC
    LIMIT 200
    `,
    inventarioItemId ? { inventarioItemId } : undefined
  );

  return rows.map((row) => ({
    id: row.id,
    inventarioItemId: row.inventario_item_id,
    inventarioItemNombre: row.item_nombre,
    unidad: row.unidad,
    tipo: row.tipo,
    cantidad: Number(row.cantidad),
    costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
    motivo: row.motivo,
    origen: row.origen,
    referenciaOrdenId: row.referencia_orden_id,
    creadoPorUsuarioId: row.creado_por_usuario_id,
    creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null)
  }));
};

/** Crea la tabla inventario_categoria si no existe (categorías creadas por el usuario que no dependen de ítems). */
const ensureInventarioCategoriaTableExists = async () => {
  try {
    await pool.execute(
      `
      CREATE TABLE IF NOT EXISTS inventario_categoria (
        id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(64) NOT NULL,
        creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_inventario_categoria_nombre (nombre)
      )
      `
    );
  } catch (error: any) {
    console.warn('Advertencia: No se pudo crear tabla inventario_categoria:', (error as Error).message);
  }
};

/** Inserta una categoría en inventario_categoria (si no existe ya). No lanza si el nombre ya existe. Devuelve la lista actualizada de categorías. */
export const crearCategoriaInventario = async (nombre: string): Promise<string[]> => {
  await ensureInventarioCategoriaTableExists();
  const n = nombre.trim();
  if (!n) return obtenerCategoriasUnicas();
  try {
    await pool.execute(
      `INSERT IGNORE INTO inventario_categoria (nombre) VALUES (:nombre)`,
      { nombre: n }
    );
  } catch (error: any) {
    throw error;
  }
  return obtenerCategoriasUnicas();
};

export const obtenerCategoriasUnicas = async () => {
  await ensureInventarioCategoriaTableExists();
  try {
    const [rows] = await pool.query(
      `
      (
        SELECT DISTINCT categoria AS nombre
        FROM inventario_item
        WHERE activo = 1 AND categoria IS NOT NULL AND TRIM(categoria) != ''
      )
      UNION
      (
        SELECT nombre FROM inventario_categoria
      )
      ORDER BY nombre
      `
    );

    return (rows as Array<{ nombre: string }>).map((row) => (row.nombre ?? '').trim()).filter(cat => cat !== '');
  } catch (error: any) {
    if (error.code === 'ER_BAD_FIELD_ERROR' || error.message?.includes('Unknown column')) {
      try {
        const [rows] = await pool.query(
          `SELECT DISTINCT categoria FROM inventario_item WHERE activo = 1 AND categoria IS NOT NULL AND categoria != '' ORDER BY categoria`
        );
        return (rows as Array<{ categoria: string }>).map((row) => row.categoria ?? '').filter(cat => cat !== '');
      } catch {
        return [];
      }
    }
    if (error.code === 'ER_NO_SUCH_TABLE') {
      return [];
    }
    throw error;
  }
};

