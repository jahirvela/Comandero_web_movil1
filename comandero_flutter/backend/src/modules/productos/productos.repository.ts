import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import type { PoolConnection } from 'mysql2/promise';
import { pool, withTransaction } from '../../db/pool.js';

interface ProductoRow extends RowDataPacket {
  id: number;
  categoria_id: number;
  categoria_nombre: string;
  nombre: string;
  descripcion: string | null;
  precio: number;
  disponible: number;
  sku: string | null;
  inventariable: number;
  creado_en: Date;
  actualizado_en: Date;
}

interface ProductoTamanoRow extends RowDataPacket {
  id: number;
  producto_id: number;
  etiqueta: string;
  precio: number;
  creado_en: Date;
  actualizado_en: Date;
}

interface ProductoIngredienteRow extends RowDataPacket {
  id: number;
  producto_id: number;
  producto_tamano_id?: number | null;
  inventario_item_id: number | null;
  categoria: string | null;
  nombre: string;
  unidad: string;
  cantidad_por_porcion: number;
  descontar_automaticamente: number;
  es_personalizado: number;
  es_opcional?: number;
  creado_en: Date;
  actualizado_en: Date;
}

type ProductoTamano = {
  id: number;
  nombre: string;
  precio: number;
};

type ProductoIngrediente = {
  id: number;
  productoTamanoId: number | null;
  inventarioItemId: number | null;
  categoria: string | null;
  nombre: string;
  unidad: string;
  cantidadPorPorcion: number;
  descontarAutomaticamente: boolean;
  esPersonalizado: boolean;
  esOpcional: boolean;
};

const mapTamanoRows = (rows: ProductoTamanoRow[]) => {
  return rows.map<ProductoTamano>((row) => ({
    id: row.id,
    nombre: row.etiqueta,
    precio: Number(row.precio)
  }));
};

const mapIngredienteRows = (rows: ProductoIngredienteRow[]) => {
  return rows.map<ProductoIngrediente>((row) => ({
    id: row.id,
    productoTamanoId: row.producto_tamano_id ?? null,
    inventarioItemId: row.inventario_item_id,
    categoria: row.categoria,
    nombre: row.nombre,
    unidad: row.unidad,
    cantidadPorPorcion: Number(row.cantidad_por_porcion),
    descontarAutomaticamente: Boolean(row.descontar_automaticamente),
    esPersonalizado: Boolean(row.es_personalizado),
    esOpcional: Boolean(row.es_opcional ?? 0)
  }));
};

const obtenerColumnasProductoIngrediente = async (
  conn: Pick<typeof pool, 'query'>
) => {
  try {
    const [rows] = await conn.query<RowDataPacket[]>(
      `
      SELECT COLUMN_NAME
      FROM information_schema.columns
      WHERE table_schema = DATABASE()
        AND table_name = 'producto_ingrediente'
        AND COLUMN_NAME IN ('es_opcional', 'producto_tamano_id')
      `
    );
    const columnas = new Set(
      rows.map((row) => (row.COLUMN_NAME as string).toLowerCase())
    );
    return {
      hasEsOpcional: columnas.has('es_opcional'),
      hasProductoTamanoId: columnas.has('producto_tamano_id')
    };
  } catch (error) {
    return { hasEsOpcional: false, hasProductoTamanoId: false };
  }
};

const obtenerTamanosPorProductoIds = async (productoIds: number[]) => {
  const map = new Map<number, ProductoTamano[]>();
  if (productoIds.length === 0) {
    return map;
  }

  const placeholders = productoIds.map(() => '?').join(', ');
  const [rows] = await pool.query<ProductoTamanoRow[]>(
    `
    SELECT
      pt.id,
      pt.producto_id,
      pt.etiqueta,
      pt.precio,
      pt.creado_en,
      pt.actualizado_en
    FROM producto_tamano pt
    WHERE pt.producto_id IN (${placeholders})
    ORDER BY pt.precio ASC, pt.id ASC
    `,
    productoIds
  );

  for (const row of rows) {
    const list = map.get(row.producto_id) ?? [];
    list.push({
      id: row.id,
      nombre: row.etiqueta,
      precio: Number(row.precio)
    });
    map.set(row.producto_id, list);
  }

  return map;
};

const obtenerTamanosPorProducto = async (productoId: number) => {
  const [rows] = await pool.query<ProductoTamanoRow[]>(
    `
    SELECT
      pt.id,
      pt.producto_id,
      pt.etiqueta,
      pt.precio,
      pt.creado_en,
      pt.actualizado_en
    FROM producto_tamano pt
    WHERE pt.producto_id = :productoId
    ORDER BY pt.precio ASC, pt.id ASC
    `,
    { productoId }
  );

  return mapTamanoRows(rows);
};

export const obtenerIngredientesPorProductoIds = async (productoIds: number[]) => {
  const map = new Map<number, ProductoIngrediente[]>();
  if (productoIds.length === 0) {
    return map;
  }

  // Verificar si la tabla existe
  try {
    const [tableCheck] = await pool.query(
      `SELECT COUNT(*) as count 
       FROM information_schema.tables 
       WHERE table_schema = DATABASE() 
       AND table_name = 'producto_ingrediente'`
    );
    
    const tableExists = (tableCheck as Array<{ count: number }>)[0].count > 0;
    
    if (!tableExists) {
      return map; // Retornar mapa vacío si la tabla no existe
    }
  } catch (checkError) {
    // Si hay error al verificar, retornar mapa vacío
    return map;
  }

  try {
    const { hasEsOpcional, hasProductoTamanoId } =
      await obtenerColumnasProductoIngrediente(pool);
    const placeholders = productoIds.map(() => '?').join(', ');
    const columnasExtra = [
      hasEsOpcional ? 'pi.es_opcional' : null,
      hasProductoTamanoId ? 'pi.producto_tamano_id' : null
    ]
      .filter(Boolean)
      .join(', ');
    const columnasExtraSql = columnasExtra ? `, ${columnasExtra}` : '';
    const [rows] = await pool.query<ProductoIngredienteRow[]>(
      `
      SELECT
        pi.id,
        pi.producto_id,
        pi.inventario_item_id,
        pi.categoria,
        pi.nombre,
        pi.unidad,
        pi.cantidad_por_porcion,
        pi.descontar_automaticamente,
        pi.es_personalizado${columnasExtraSql},
        pi.creado_en,
        pi.actualizado_en
      FROM producto_ingrediente pi
      WHERE pi.producto_id IN (${placeholders})
      ORDER BY pi.id ASC
      `,
      productoIds
    );

    for (const row of rows) {
      const list = map.get(row.producto_id) ?? [];
      list.push({
        id: row.id,
        productoTamanoId: row.producto_tamano_id ?? null,
        inventarioItemId: row.inventario_item_id,
        categoria: row.categoria,
        nombre: row.nombre,
        unidad: row.unidad,
        cantidadPorPorcion: Number(row.cantidad_por_porcion),
        descontarAutomaticamente: Boolean(row.descontar_automaticamente),
        esPersonalizado: Boolean(row.es_personalizado),
        esOpcional: Boolean(row.es_opcional ?? 0)
      });
      map.set(row.producto_id, list);
    }
  } catch (error: any) {
    // Si falla, retornar mapa vacío
    console.warn('Error al obtener ingredientes por producto IDs:', error.message);
  }

  return map;
};

const obtenerIngredientesPorProducto = async (productoId: number) => {
  // Verificar si la tabla existe
  try {
    const [tableCheck] = await pool.query(
      `SELECT COUNT(*) as count 
       FROM information_schema.tables 
       WHERE table_schema = DATABASE() 
       AND table_name = 'producto_ingrediente'`
    );
    
    const tableExists = (tableCheck as Array<{ count: number }>)[0].count > 0;
    
    if (!tableExists) {
      return []; // Retornar array vacío si la tabla no existe
    }
  } catch (checkError) {
    // Si hay error al verificar, retornar array vacío
    return [];
  }

  try {
    const { hasEsOpcional, hasProductoTamanoId } =
      await obtenerColumnasProductoIngrediente(pool);
    const columnasExtra = [
      hasEsOpcional ? 'pi.es_opcional' : null,
      hasProductoTamanoId ? 'pi.producto_tamano_id' : null
    ]
      .filter(Boolean)
      .join(', ');
    const columnasExtraSql = columnasExtra ? `, ${columnasExtra}` : '';
    const [rows] = await pool.query<ProductoIngredienteRow[]>(
      `
      SELECT
        pi.id,
        pi.producto_id,
        pi.inventario_item_id,
        pi.categoria,
        pi.nombre,
        pi.unidad,
        pi.cantidad_por_porcion,
        pi.descontar_automaticamente,
        pi.es_personalizado${columnasExtraSql},
        pi.creado_en,
        pi.actualizado_en
      FROM producto_ingrediente pi
      WHERE pi.producto_id = :productoId
      ORDER BY pi.id ASC
      `,
      { productoId }
    );

    return mapIngredienteRows(rows);
  } catch (error: any) {
    // Si falla, retornar array vacío
    console.warn(`Error al obtener ingredientes del producto ${productoId}:`, error.message);
    return [];
  }
};

const insertarTamanosProducto = async (
  conn: PoolConnection,
  productoId: number,
  tamanos: Array<{ nombre: string; precio: number }>
) => {
  if (!tamanos.length) return;

  for (const tamano of tamanos) {
    await conn.execute(
      `
      INSERT INTO producto_tamano (producto_id, etiqueta, precio)
      VALUES (:productoId, :etiqueta, :precio)
      `,
      {
        productoId,
        etiqueta: tamano.nombre.trim(),
        precio: tamano.precio
      }
    );
  }
};

const reemplazarTamanosProducto = async (
  conn: PoolConnection,
  productoId: number,
  tamanos: Array<{ nombre: string; precio: number }>
) => {
  await conn.execute(
    `
    DELETE FROM producto_tamano
    WHERE producto_id = :productoId
    `,
    { productoId }
  );

  if (tamanos.length > 0) {
    await insertarTamanosProducto(conn, productoId, tamanos);
  }
};

const insertarIngredientesProducto = async (
  conn: PoolConnection,
  productoId: number,
  ingredientes: Array<{
    productoTamanoId?: number | null;
    inventarioItemId?: number | null;
    categoria?: string | null;
    nombre: string;
    unidad: string;
    cantidadPorPorcion: number;
    descontarAutomaticamente: boolean;
    esPersonalizado: boolean;
    esOpcional?: boolean;
  }>
) => {
  if (!ingredientes.length) return;

  // Verificar si la tabla existe antes de insertar
  let tableExists = false;
  try {
    const [tableCheck] = await conn.execute(
      `SELECT COUNT(*) as count 
       FROM information_schema.tables 
       WHERE table_schema = DATABASE() 
       AND table_name = 'producto_ingrediente'`
    );
    
    tableExists = (tableCheck as Array<{ count: number }>)[0].count > 0;
    
    if (!tableExists) {
      console.warn('Tabla producto_ingrediente no existe. Los ingredientes no se guardarán en producto_ingrediente, pero los personalizados se crearán en inventario.');
    }
  } catch (checkError) {
    // Si hay error al verificar, intentar insertar de todas formas
    console.warn('Error al verificar tabla producto_ingrediente:', checkError);
    tableExists = false;
  }

  const { hasEsOpcional, hasProductoTamanoId } =
    await obtenerColumnasProductoIngrediente(conn);

  for (const ingrediente of ingredientes) {
    try {
      let inventarioItemId = ingrediente.inventarioItemId;

      // Si no tiene inventarioItemId, debe existir en el inventario primero
      // Ya no se crean ingredientes personalizados automáticamente
      if (!inventarioItemId) {
        // El ingrediente debe existir previamente en el inventario
        // Si no tiene inventarioItemId, simplemente lo omitimos (será null)
        console.warn(`⚠️ Ingrediente "${ingrediente.nombre}" no tiene inventarioItemId. Debe agregarse primero al inventario.`);
        inventarioItemId = null;
      }

      // Solo intentar insertar en producto_ingrediente si la tabla existe
      if (tableExists) {
        try {
          const [insertResult] = await conn.execute<ResultSetHeader>(
            `
            INSERT INTO producto_ingrediente (
              producto_id,
              inventario_item_id,
              categoria,
              nombre,
              unidad,
              cantidad_por_porcion,
              descontar_automaticamente,
              es_personalizado
              ${hasEsOpcional ? ', es_opcional' : ''}
              ${hasProductoTamanoId ? ', producto_tamano_id' : ''}
            )
            VALUES (
              :productoId,
              :inventarioItemId,
              :categoria,
              :nombre,
              :unidad,
              :cantidadPorPorcion,
              :descontarAutomaticamente,
              :esPersonalizado
              ${hasEsOpcional ? ', :esOpcional' : ''}
              ${hasProductoTamanoId ? ', :productoTamanoId' : ''}
            )
            `,
            {
              productoId,
              inventarioItemId: inventarioItemId ?? null,
              categoria: ingrediente.categoria ?? null,
              nombre: ingrediente.nombre.trim(),
              unidad: ingrediente.unidad.trim(),
              cantidadPorPorcion: ingrediente.cantidadPorPorcion,
              descontarAutomaticamente: ingrediente.descontarAutomaticamente ? 1 : 0,
              esPersonalizado: ingrediente.esPersonalizado ? 1 : 0,
              esOpcional: (ingrediente.esOpcional ?? false) ? 1 : 0,
              productoTamanoId: ingrediente.productoTamanoId ?? null
            }
          );
          
          console.log(`✅ Ingrediente guardado en BD: ${ingrediente.nombre} (Producto ID: ${productoId}, Inventario ID: ${inventarioItemId ?? 'N/A'}, Ingrediente ID: ${insertResult.insertId})`);
        } catch (insertError: any) {
          throw insertError;
        }
      } else {
        // Si la tabla no existe pero creamos un item en inventario, loguear que se creó en inventario
        if (inventarioItemId) {
          console.log(`✅ Ingrediente personalizado agregado al inventario (tabla producto_ingrediente no existe): ${ingrediente.nombre} (Inventario ID: ${inventarioItemId})`);
        }
      }
    } catch (insertError: any) {
      // Si falla la inserción, registrar el error pero no fallar todo el proceso
      console.error(`❌ Error al insertar ingrediente ${ingrediente.nombre} en producto_ingrediente:`, insertError.message);
      console.error('Detalles del error:', insertError);
      // Re-lanzar el error para que la transacción pueda hacer rollback si es necesario
      throw insertError;
    }
  }
};

const reemplazarIngredientesProducto = async (
  conn: PoolConnection,
  productoId: number,
  ingredientes: Array<{
    productoTamanoId?: number | null;
    inventarioItemId?: number | null;
    categoria?: string | null;
    nombre: string;
    unidad: string;
    cantidadPorPorcion: number;
    descontarAutomaticamente: boolean;
    esPersonalizado: boolean;
    esOpcional?: boolean;
  }>
) => {
  // Verificar si la tabla existe antes de operar
  try {
    const [tableCheck] = await conn.execute(
      `SELECT COUNT(*) as count 
       FROM information_schema.tables 
       WHERE table_schema = DATABASE() 
       AND table_name = 'producto_ingrediente'`
    );
    
    const tableExists = (tableCheck as Array<{ count: number }>)[0].count > 0;
    
    if (!tableExists) {
      console.warn('Tabla producto_ingrediente no existe. Los ingredientes no se actualizarán.');
      return;
    }
  } catch (checkError) {
    console.warn('Error al verificar tabla producto_ingrediente:', checkError);
    return;
  }

  try {
    await conn.execute(
      `
      DELETE FROM producto_ingrediente
      WHERE producto_id = :productoId
      `,
      { productoId }
    );

    if (ingredientes.length > 0) {
      await insertarIngredientesProducto(conn, productoId, ingredientes);
    }
  } catch (error: any) {
    // Si falla, registrar pero no fallar todo el proceso
    console.warn(`Error al reemplazar ingredientes del producto ${productoId}:`, error.message);
  }
};

export const listarProductos = async (categoriaId?: number) => {
  const [rows] = await pool.query<ProductoRow[]>(
    `
    SELECT
      p.*,
      c.nombre AS categoria_nombre
    FROM producto p
    JOIN categoria c ON c.id = p.categoria_id
    ${categoriaId ? 'WHERE p.categoria_id = :categoriaId' : ''}
    ORDER BY c.nombre, p.nombre
    `,
    categoriaId ? { categoriaId } : undefined
  );

  const productos = rows.map((row) => ({
    id: row.id,
    categoriaId: row.categoria_id,
    categoriaNombre: row.categoria_nombre,
    nombre: row.nombre,
    descripcion: row.descripcion,
    precio: Number(row.precio),
    disponible: Boolean(row.disponible),
    sku: row.sku,
    inventariable: Boolean(row.inventariable),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en,
    tamanos: [],
    ingredientes: []
  }));

  const tamanosMap = await obtenerTamanosPorProductoIds(rows.map((row) => row.id));
  const ingredientesMap = await obtenerIngredientesPorProductoIds(rows.map((row) => row.id));

  return productos.map((producto) => ({
    ...producto,
    tamanos: tamanosMap.get(producto.id) ?? [],
    ingredientes: ingredientesMap.get(producto.id) ?? []
  }));
};

export const obtenerProductoPorId = async (id: number) => {
  const [rows] = await pool.query<ProductoRow[]>(
    `
    SELECT
      p.*,
      c.nombre AS categoria_nombre
    FROM producto p
    JOIN categoria c ON c.id = p.categoria_id
    WHERE p.id = :id
    `,
    { id }
  );

  const row = rows[0];
  if (!row) return null;

  const tamanos = await obtenerTamanosPorProducto(row.id);
  const ingredientes = await obtenerIngredientesPorProducto(row.id);

  return {
    id: row.id,
    categoriaId: row.categoria_id,
    categoriaNombre: row.categoria_nombre,
    nombre: row.nombre,
    descripcion: row.descripcion,
    precio: Number(row.precio),
    disponible: Boolean(row.disponible),
    sku: row.sku,
    inventariable: Boolean(row.inventariable),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en,
    tamanos,
    ingredientes
  };
};

export const crearProducto = async ({
  categoriaId,
  nombre,
  descripcion,
  precio,
  disponible,
  sku,
  inventariable,
  tamanos,
  ingredientes
}: {
  categoriaId: number;
  nombre: string;
  descripcion?: string | null;
  precio: number;
  disponible: boolean;
  sku?: string | null;
  inventariable: boolean;
  tamanos?: Array<{ nombre: string; precio: number }>;
  ingredientes?: Array<{
    inventarioItemId?: number | null;
    categoria?: string | null;
    nombre: string;
    unidad: string;
    cantidadPorPorcion: number;
    descontarAutomaticamente: boolean;
    esPersonalizado: boolean;
    esOpcional?: boolean;
  }>;
}) => {
  return withTransaction(async (conn) => {
    const [result] = await conn.execute<ResultSetHeader>(
      `
      INSERT INTO producto (
        categoria_id,
        nombre,
        descripcion,
        precio,
        disponible,
        sku,
        inventariable
      )
      VALUES (:categoriaId, :nombre, :descripcion, :precio, :disponible, :sku, :inventariable)
      `,
      {
        categoriaId,
        nombre,
        descripcion: descripcion ?? null,
        precio,
        disponible: disponible ? 1 : 0,
        sku: sku ?? null,
        inventariable: inventariable ? 1 : 0
      }
    );

    const productoId = result.insertId;

    if (tamanos && tamanos.length > 0) {
      await insertarTamanosProducto(conn, productoId, tamanos);
    }

    if (ingredientes && ingredientes.length > 0) {
      await insertarIngredientesProducto(conn, productoId, ingredientes);
    }

    return productoId;
  });
};

export const actualizarProducto = async (
  id: number,
  {
    categoriaId,
    nombre,
    descripcion,
    precio,
    disponible,
    sku,
    inventariable,
    tamanos,
    ingredientes
  }: {
    categoriaId?: number;
    nombre?: string;
    descripcion?: string | null;
    precio?: number;
    disponible?: boolean;
    sku?: string | null;
    inventariable?: boolean;
    tamanos?: Array<{ nombre: string; precio: number }>;
    ingredientes?: Array<{
      inventarioItemId?: number | null;
      categoria?: string | null;
      nombre: string;
      unidad: string;
      cantidadPorPorcion: number;
      descontarAutomaticamente: boolean;
      esPersonalizado: boolean;
      esOpcional?: boolean;
    }>;
  }
) => {
  const fields: string[] = [];
  const params: Record<string, unknown> = { id };

  if (categoriaId !== undefined) {
    fields.push('categoria_id = :categoriaId');
    params.categoriaId = categoriaId;
  }
  if (nombre !== undefined) {
    fields.push('nombre = :nombre');
    params.nombre = nombre;
  }
  if (descripcion !== undefined) {
    fields.push('descripcion = :descripcion');
    params.descripcion = descripcion ?? null;
  }
  if (precio !== undefined) {
    fields.push('precio = :precio');
    params.precio = precio;
  }
  if (disponible !== undefined) {
    fields.push('disponible = :disponible');
    params.disponible = disponible ? 1 : 0;
  }
  if (sku !== undefined) {
    fields.push('sku = :sku');
    params.sku = sku ?? null;
  }
  if (inventariable !== undefined) {
    fields.push('inventariable = :inventariable');
    params.inventariable = inventariable ? 1 : 0;
  }

  if (fields.length === 0 && tamanos === undefined && ingredientes === undefined) {
    return;
  }

  await withTransaction(async (conn) => {
    if (fields.length > 0) {
      await conn.execute(
        `
        UPDATE producto
        SET ${fields.join(', ')}, actualizado_en = NOW()
        WHERE id = :id
        `,
        params
      );
    } else if (tamanos !== undefined) {
      await conn.execute(
        `
        UPDATE producto
        SET actualizado_en = NOW()
        WHERE id = :id
        `,
        { id }
      );
    }

    if (tamanos !== undefined) {
      await reemplazarTamanosProducto(conn, id, tamanos);
    }

    if (ingredientes !== undefined) {
      await reemplazarIngredientesProducto(conn, id, ingredientes);
    }
  });
};

export const desactivarProducto = async (id: number) => {
  await withTransaction(async (conn) => {
    await conn.execute(
      `
      DELETE FROM producto_ingrediente
      WHERE producto_id = :id
      `,
      { id }
    );

    await conn.execute(
      `
      DELETE FROM producto_tamano
      WHERE producto_id = :id
      `,
      { id }
    );

    await conn.execute(
      `
      DELETE FROM producto
      WHERE id = :id
      `,
      { id }
    );
  });
};

