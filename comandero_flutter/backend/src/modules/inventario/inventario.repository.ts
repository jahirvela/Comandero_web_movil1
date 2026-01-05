import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool, withTransaction } from '../../db/pool.js';

interface InventarioItemRow extends RowDataPacket {
  id: number;
  nombre: string;
  categoria: string | null;
  unidad: string;
  cantidad_actual: number;
  stock_minimo: number;
  stock_maximo: number | null;
  costo_unitario: number | null;
  proveedor: string | null;
  activo: number;
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
      categoria: row.categoria ?? '',
      unidad: row.unidad,
      cantidadActual: Number(row.cantidad_actual),
      stockMinimo: Number(row.stock_minimo),
      stockMaximo: row.stock_maximo === null ? null : Number(row.stock_maximo),
      costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
      proveedor: row.proveedor ?? null,
      activo: Boolean(row.activo),
      creadoEn: row.creado_en,
      actualizadoEn: row.actualizado_en
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
        categoria: '',
        unidad: row.unidad,
        cantidadActual: Number(row.cantidad_actual),
        stockMinimo: Number(row.stock_minimo),
        stockMaximo: (row as any).stock_maximo === null ? null : Number((row as any).stock_maximo),
        costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
        proveedor: (row as any).proveedor ?? null,
        activo: Boolean(row.activo),
        creadoEn: row.creado_en,
        actualizadoEn: row.actualizado_en
      }));
    }
    throw error;
  }
};

export const obtenerInsumoPorId = async (id: number) => {
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
    categoria: row.categoria ?? '',
    unidad: row.unidad,
    cantidadActual: Number(row.cantidad_actual),
    stockMinimo: Number(row.stock_minimo),
    stockMaximo: row.stock_maximo === null ? null : Number(row.stock_maximo),
    costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
    proveedor: row.proveedor ?? null,
    activo: Boolean(row.activo),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en
  };
};

// Función auxiliar para verificar y crear la columna categoria si no existe
const ensureCategoriaColumnExists = async () => {
  try {
    const [columns] = await pool.query<Array<{ COLUMN_NAME: string }>>(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'categoria'
      `
    );

    if (columns.length === 0) {
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
    const [columns] = await pool.query<Array<{ COLUMN_NAME: string }>>(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'proveedor'
      `
    );

    if (columns.length === 0) {
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
    const [columns] = await pool.query<Array<{ COLUMN_NAME: string }>>(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'stock_maximo'
      `
    );

    if (columns.length === 0) {
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

export const crearInsumo = async ({
  nombre,
  categoria,
  unidad,
  cantidadActual,
  stockMinimo,
  stockMaximo,
  costoUnitario,
  proveedor,
  activo
}: {
  nombre: string;
  categoria: string;
  unidad: string;
  cantidadActual: number;
  stockMinimo: number;
  stockMaximo?: number | null;
  costoUnitario?: number | null;
  proveedor?: string | null;
  activo: boolean;
}) => {
  try {
    // Asegurar que las columnas categoria, proveedor y stock_maximo existen antes de insertar
    await ensureCategoriaColumnExists();
    await ensureProveedorColumnExists();
    await ensureStockMaximoColumnExists();
    
    // Usar transacción para eliminar duplicados y crear nuevo registro de forma atómica
    return await withTransaction(async (conn) => {
      // Primero, eliminar cualquier registro existente con el mismo nombre (activo o inactivo)
      // Esto evita problemas con el constraint único ux_inventario_nombre
      try {
        // Obtener IDs de registros existentes con ese nombre
        const [existingRows] = await conn.query<Array<{ id: number }>>(
          `SELECT id FROM inventario_item WHERE nombre = :nombre`,
          { nombre }
        );
        
        if (existingRows.length > 0) {
          const existingIds = existingRows.map(row => row.id);
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
      
      // Crear el nuevo registro
      const [result] = await conn.execute<ResultSetHeader>(
      `
      INSERT INTO inventario_item (nombre, categoria, unidad, cantidad_actual, stock_minimo, stock_maximo, costo_unitario, proveedor, activo)
      VALUES (:nombre, :categoria, :unidad, :cantidadActual, :stockMinimo, :stockMaximo, :costoUnitario, :proveedor, :activo)
      `,
      {
        nombre,
        categoria,
        unidad,
        cantidadActual,
        stockMinimo,
        stockMaximo: stockMaximo ?? null,
        costoUnitario: costoUnitario ?? null,
        proveedor: proveedor ?? null,
        activo: activo ? 1 : 0
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
    categoria,
    unidad,
    cantidadActual,
    stockMinimo,
    stockMaximo,
    costoUnitario,
    proveedor,
    activo
  }: {
    nombre?: string;
    categoria?: string;
    unidad?: string;
    cantidadActual?: number;
    stockMinimo?: number;
    stockMaximo?: number | null;
    costoUnitario?: number | null;
    proveedor?: string | null;
    activo?: boolean;
  }
) => {
  // Asegurar que las columnas categoria, proveedor y stock_maximo existen antes de actualizar
  if (categoria !== undefined) {
    await ensureCategoriaColumnExists();
  }
  if (proveedor !== undefined) {
    await ensureProveedorColumnExists();
  }
  if (stockMaximo !== undefined) {
    await ensureStockMaximoColumnExists();
  }
  const fields: string[] = [];
  const params: Record<string, unknown> = { id };

  if (nombre !== undefined) {
    fields.push('nombre = :nombre');
    params.nombre = nombre;
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
    creadoEn: row.creado_en
  }));
};

export const obtenerCategoriasUnicas = async () => {
  try {
    const [rows] = await pool.query<{ categoria: string }[]>(
      `
      SELECT DISTINCT categoria
      FROM inventario_item
      WHERE activo = 1 AND categoria IS NOT NULL AND categoria != ''
      ORDER BY categoria
      `
    );

    return rows.map((row) => row.categoria ?? '').filter(cat => cat !== '');
  } catch (error: any) {
    // Si la columna no existe, retornar array vacío
    if (error.code === 'ER_BAD_FIELD_ERROR' || error.message?.includes('Unknown column')) {
      console.warn('La columna categoria no existe en inventario_item. Ejecuta el script de migración.');
      return [];
    }
    throw error;
  }
};

