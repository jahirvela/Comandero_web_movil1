import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool, withTransaction } from '../../db/pool.js';
import { utcToMxISO } from '../../config/time.js';

interface OrdenRow extends RowDataPacket {
  id: number;
  mesa_id: number | null;
  mesa_codigo: string | null;
  cliente_id: number | null;
  cliente_nombre: string | null;
  subtotal: number;
  descuento_total: number;
  impuesto_total: number;
  propina_sugerida: number | null;
  total: number;
  estado_orden_id: number;
  estado_nombre: string;
  creado_por_usuario_id: number | null;
  cerrado_por_usuario_id: number | null;
  creado_en: Date;
  actualizado_en: Date;
}

interface OrdenItemRow extends RowDataPacket {
  id: number;
  orden_id: number;
  producto_id: number;
  producto_nombre: string;
  producto_tamano_id: number | null;
  producto_tamano_etiqueta: string | null;
  cantidad: number;
  precio_unitario: number;
  total_linea: number;
  nota: string | null;
}

interface OrdenItemModificadorRow extends RowDataPacket {
  id: number;
  orden_item_id: number;
  modificador_opcion_id: number;
  modificador_opcion_nombre: string;
  precio_unitario: number;
}

interface EstadoOrdenRow extends RowDataPacket {
  id: number;
  nombre: string;
}

export const obtenerEstadoOrdenPorNombre = async (nombre: string) => {
  const [rows] = await pool.query<EstadoOrdenRow[]>(
    `
    SELECT id, nombre
    FROM estado_orden
    WHERE nombre = :nombre
    LIMIT 1
    `,
    { nombre }
  );
  return rows[0] ?? null;
};

export const listarOrdenes = async ({
  estadoOrdenId,
  mesaId,
  incluirCerradas = false
}: {
  estadoOrdenId?: number;
  mesaId?: number;
  /** Si true (p. ej. para el cajero), no se excluye "cerrada": así aparecen cuentas por cobrar */
  incluirCerradas?: boolean;
}) => {
  const conditions: string[] = [];
  const params: Record<string, unknown> = {};

  if (estadoOrdenId) {
    conditions.push('o.estado_orden_id = :estadoOrdenId');
    params.estadoOrdenId = estadoOrdenId;
  }
  if (mesaId !== undefined) {
    if (mesaId === null) {
      // Si mesaId es null explícitamente, buscar órdenes "para llevar"
      conditions.push('o.mesa_id IS NULL');
    } else {
      // Si mesaId tiene valor, buscar órdenes de esa mesa
      conditions.push('o.mesa_id = :mesaId');
      params.mesaId = mesaId;
    }
  }

  // Por defecto excluir pagada, cancelada y cerrada (solo órdenes activas).
  // Con incluirCerradas=true (cajero) solo excluimos pagada y cancelada para ver cuentas por cobrar.
  const estadoExcluidos = incluirCerradas ? ['pagada', 'cancelada'] : ['pagada', 'cancelada', 'cerrada'];
  estadoExcluidos.forEach((estado, i) => {
    params[`estadoExcluido${i}`] = estado;
  });
  const estadoExcluidosCondition = estadoExcluidos.map((_, i) => {
    return `eo.nombre != :estadoExcluido${i}`;
  }).join(' AND ');

  // Construir WHERE clause combinando condiciones
  const allConditions = [...conditions, estadoExcluidosCondition];
  const whereClause = allConditions.length > 0 ? `WHERE ${allConditions.join(' AND ')}` : '';

  const [rows] = await pool.query<OrdenRow[]>(
    `
    SELECT
      o.*,
      m.codigo AS mesa_codigo,
      eo.nombre AS estado_nombre,
      u.nombre AS creado_por_nombre,
      u.username AS creado_por_username
    FROM orden o
    LEFT JOIN mesa m ON m.id = o.mesa_id
    JOIN estado_orden eo ON eo.id = o.estado_orden_id
    LEFT JOIN usuario u ON u.id = o.creado_por_usuario_id
    ${whereClause}
    ORDER BY o.creado_en DESC
    LIMIT 200
    `,
    params
  );

  return rows.map((row) => ({
    id: row.id,
    mesaId: row.mesa_id,
    mesaCodigo: row.mesa_codigo,
    clienteId: row.cliente_id,
    clienteNombre: row.cliente_nombre,
    subtotal: Number(row.subtotal),
    descuentoTotal: Number(row.descuento_total),
    impuestoTotal: Number(row.impuesto_total),
    propinaSugerida: row.propina_sugerida === null ? null : Number(row.propina_sugerida),
    total: Number(row.total),
    estadoOrdenId: row.estado_orden_id,
    estadoNombre: row.estado_nombre,
    creadoPorUsuarioId: row.creado_por_usuario_id,
    creadoPorNombre: (row as any).creado_por_nombre,
    creadoPorUsuarioNombre: (row as any).creado_por_nombre ?? (row as any).creado_por_username,
    tiempoEstimadoPreparacion: (row as any).tiempo_estimado_preparacion ?? null,
    cerradoPorUsuarioId: row.cerrado_por_usuario_id,
    creadoEn: utcToMxISO(row.creado_en) ?? '',
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? ''
  }));
};

export const obtenerOrdenBasePorId = async (id: number) => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT
      o.*,
      m.codigo AS mesa_codigo,
      eo.nombre AS estado_nombre,
      c.telefono AS cliente_telefono,
      u.nombre AS creado_por_nombre,
      u.username AS creado_por_username
    FROM orden o
    LEFT JOIN mesa m ON m.id = o.mesa_id
    JOIN estado_orden eo ON eo.id = o.estado_orden_id
    LEFT JOIN cliente c ON c.id = o.cliente_id
    LEFT JOIN usuario u ON u.id = o.creado_por_usuario_id
    WHERE o.id = :id
    `,
    { id }
  );

  const row = rows[0];
  if (!row) return null;

  return {
    id: row.id,
    mesaId: row.mesa_id,
    mesaCodigo: row.mesa_codigo,
    clienteId: row.cliente_id,
    clienteNombre: row.cliente_nombre,
    clienteTelefono: row.cliente_telefono,
    subtotal: Number(row.subtotal),
    descuentoTotal: Number(row.descuento_total),
    impuestoTotal: Number(row.impuesto_total),
    propinaSugerida: row.propina_sugerida === null ? null : Number(row.propina_sugerida),
    total: Number(row.total),
    estadoOrdenId: row.estado_orden_id,
    estadoNombre: row.estado_nombre,
    creadoPorUsuarioId: row.creado_por_usuario_id,
    creadoPorNombre: row.creado_por_nombre,
    creadoPorUsuarioNombre: row.creado_por_nombre ?? row.creado_por_username,
    cerradoPorUsuarioId: row.cerrado_por_usuario_id,
    tiempoEstimadoPreparacion: (row as any).tiempo_estimado_preparacion ?? null,
    creadoEn: utcToMxISO(row.creado_en) ?? '',
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? ''
  };
};

export const obtenerItemsOrden = async (ordenId: number) => {
  // Usar solo p.nombre y pt.etiqueta (JOINs) para no depender de columnas
  // producto_nombre/producto_tamano_etiqueta en orden_item (pueden no existir en BD antigua).
  const [rows] = await pool.query<OrdenItemRow[]>(
    `
    SELECT
      oi.id,
      oi.orden_id,
      oi.producto_id,
      oi.producto_tamano_id,
      oi.cantidad,
      oi.precio_unitario,
      oi.total_linea,
      oi.nota,
      p.nombre AS producto_nombre,
      pt.etiqueta AS producto_tamano_etiqueta
    FROM orden_item oi
    LEFT JOIN producto p ON p.id = oi.producto_id
    LEFT JOIN producto_tamano pt ON pt.id = oi.producto_tamano_id
    WHERE oi.orden_id = :ordenId
    ORDER BY oi.id
    `,
    { ordenId }
  );
  return rows.map((row) => ({
    id: row.id,
    ordenId: row.orden_id,
    productoId: row.producto_id,
    productoNombre: row.producto_nombre ?? 'Producto',
    productoTamanoId: row.producto_tamano_id,
    productoTamanoEtiqueta: row.producto_tamano_etiqueta ?? null,
    cantidad: Number(row.cantidad),
    precioUnitario: Number(row.precio_unitario),
    totalLinea: Number(row.total_linea),
    nota: row.nota
  }));
};

export const obtenerModificadoresItem = async (ordenItemIds: number[]) => {
  if (ordenItemIds.length === 0) return [];

  const [rows] = await pool.query<OrdenItemModificadorRow[]>(
    `
    SELECT
      oim.*,
      mo.nombre AS modificador_opcion_nombre
    FROM orden_item_modificador oim
    JOIN modificador_opcion mo ON mo.id = oim.modificador_opcion_id
    WHERE oim.orden_item_id IN ( ${ordenItemIds.map(() => '?').join(', ')} )
    `,
    ordenItemIds
  );

  return rows.map((row) => ({
    id: row.id,
    ordenItemId: row.orden_item_id,
    modificadorOpcionId: row.modificador_opcion_id,
    modificadorOpcionNombre: row.modificador_opcion_nombre,
    precioUnitario: Number(row.precio_unitario)
  }));
};

export const crearOrden = async ({
  mesaId,
  reservaId,
  clienteId,
  clienteNombre,
  subtotal,
  descuentoTotal,
  impuestoTotal,
  propinaSugerida,
  total,
  estadoOrdenId,
  creadoPorUsuarioId,
  items
}: {
  mesaId?: number | null;
  reservaId?: number | null;
  clienteId?: number | null;
  clienteNombre?: string | null;
  subtotal: number;
  descuentoTotal: number;
  impuestoTotal: number;
  propinaSugerida?: number | null;
  total: number;
  estadoOrdenId: number;
  creadoPorUsuarioId?: number | null;
  items: Array<{
    productoId: number;
    productoTamanoId?: number | null;
    cantidad: number;
    precioUnitario: number;
    nota?: string | null;
    modificadores?: Array<{ modificadorOpcionId: number; precioUnitario?: number }>;
  }>;
}) => {
  return withTransaction(async (conn) => {
    const [result] = await conn.execute<ResultSetHeader>(
      `
      INSERT INTO orden (
        mesa_id,
        reserva_id,
        cliente_id,
        cliente_nombre,
        subtotal,
        descuento_total,
        impuesto_total,
        propina_sugerida,
        total,
        estado_orden_id,
        creado_por_usuario_id
      )
      VALUES (
        :mesaId,
        :reservaId,
        :clienteId,
        :clienteNombre,
        :subtotal,
        :descuentoTotal,
        :impuestoTotal,
        :propinaSugerida,
        :total,
        :estadoOrdenId,
        :creadoPorUsuarioId
      )
      `,
      {
        mesaId: mesaId ?? null,
        reservaId: reservaId ?? null,
        clienteId: clienteId ?? null,
        clienteNombre: clienteNombre ?? null,
        subtotal,
        descuentoTotal,
        impuestoTotal,
        propinaSugerida: propinaSugerida ?? null,
        total,
        estadoOrdenId,
        creadoPorUsuarioId: creadoPorUsuarioId ?? null
      }
    );

    const ordenId = result.insertId;

    for (const item of items) {
      const [itemResult] = await conn.execute<ResultSetHeader>(
        `
        INSERT INTO orden_item (
          orden_id,
          producto_id,
          producto_tamano_id,
          cantidad,
          precio_unitario,
          nota
        )
        VALUES (
          :ordenId,
          :productoId,
          :productoTamanoId,
          :cantidad,
          :precioUnitario,
          :nota
        )
        `,
        {
          ordenId,
          productoId: item.productoId,
          productoTamanoId: item.productoTamanoId ?? null,
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
          nota: item.nota ?? null
        }
      );

      const ordenItemId = itemResult.insertId;

      if (item.modificadores && item.modificadores.length > 0) {
        const values = item.modificadores.map((mod) => [
          ordenItemId,
          mod.modificadorOpcionId,
          mod.precioUnitario ?? 0
        ]);
        await conn.query(
          `
          INSERT INTO orden_item_modificador (
            orden_item_id,
            modificador_opcion_id,
            precio_unitario
          )
          VALUES ?
          `,
          [values]
        );
      }
    }

    return ordenId;
  });
};

export const actualizarOrden = async (
  id: number,
  {
    mesaId,
    reservaId,
    clienteId,
    clienteNombre
  }: {
    mesaId?: number | null;
    reservaId?: number | null;
    clienteId?: number | null;
    clienteNombre?: string | null;
  }
) => {
  const fields: string[] = [];
  const params: Record<string, unknown> = { id };

  if (mesaId !== undefined) {
    fields.push('mesa_id = :mesaId');
    params.mesaId = mesaId ?? null;
  }
  if (reservaId !== undefined) {
    fields.push('reserva_id = :reservaId');
    params.reservaId = reservaId ?? null;
  }
  if (clienteId !== undefined) {
    fields.push('cliente_id = :clienteId');
    params.clienteId = clienteId ?? null;
  }
  if (clienteNombre !== undefined) {
    fields.push('cliente_nombre = :clienteNombre');
    params.clienteNombre = clienteNombre ?? null;
  }

  if (fields.length === 0) return;

  await pool.execute(
    `
    UPDATE orden
    SET ${fields.join(', ')}, actualizado_en = NOW()
    WHERE id = :id
    `,
    params
  );
};

export const actualizarEstadoOrden = async (
  id: number,
  estadoOrdenId: number,
  cerradoPorUsuarioId?: number | null
) => {
  await pool.execute(
    `
    UPDATE orden
    SET estado_orden_id = :estadoOrdenId,
        cerrado_por_usuario_id = CASE
          WHEN :estadoOrdenId IN (
            SELECT id FROM estado_orden WHERE nombre IN ('pagada', 'cancelada')
          ) THEN :cerradoPorUsuarioId
          ELSE cerrado_por_usuario_id
        END,
        actualizado_en = NOW()
    WHERE id = :id
    `,
    {
      id,
      estadoOrdenId,
      cerradoPorUsuarioId: cerradoPorUsuarioId ?? null
    }
  );
};

export const actualizarTiempoEstimadoPreparacion = async (
  id: number,
  tiempoEstimado: number
) => {
  await pool.execute(
    `
    UPDATE orden
    SET tiempo_estimado_preparacion = :tiempoEstimado,
        actualizado_en = NOW()
    WHERE id = :id
    `,
    { id, tiempoEstimado }
  );
};

export const agregarItemsAOrden = async (
  ordenId: number,
  items: Array<{
    productoId: number;
    productoTamanoId?: number | null;
    cantidad: number;
    precioUnitario: number;
    nota?: string | null;
    modificadores?: Array<{ modificadorOpcionId: number; precioUnitario?: number }>;
  }>
) => {
  await withTransaction(async (conn) => {
    for (const item of items) {
      const [itemResult] = await conn.execute<ResultSetHeader>(
        `
        INSERT INTO orden_item (
          orden_id,
          producto_id,
          producto_tamano_id,
          cantidad,
          precio_unitario,
          nota
        )
        VALUES (
          :ordenId,
          :productoId,
          :productoTamanoId,
          :cantidad,
          :precioUnitario,
          :nota
        )
        `,
        {
          ordenId,
          productoId: item.productoId,
          productoTamanoId: item.productoTamanoId ?? null,
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
          nota: item.nota ?? null
        }
      );

      const ordenItemId = itemResult.insertId;

      if (item.modificadores && item.modificadores.length > 0) {
        const values = item.modificadores.map((mod) => [
          ordenItemId,
          mod.modificadorOpcionId,
          mod.precioUnitario ?? 0
        ]);
        await conn.query(
          `
          INSERT INTO orden_item_modificador (
            orden_item_id,
            modificador_opcion_id,
            precio_unitario
          )
          VALUES ?
          `,
          [values]
        );
      }
    }
  });
};

export const listarEstadosOrden = async () => {
  const [rows] = await pool.query<EstadoOrdenRow[]>(
    `
    SELECT id, nombre
    FROM estado_orden
    ORDER BY id
    `
  );
  return rows.map((row) => ({
    id: row.id,
    nombre: row.nombre
  }));
};

/**
 * IDs de órdenes que están en estado "listo" o "listo para recoger"
 * (para sincronizar descuento de inventario de órdenes ya marcadas).
 */
export const listarOrdenIdsEnEstadoListo = async (): Promise<number[]> => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT o.id
    FROM orden o
    JOIN estado_orden eo ON eo.id = o.estado_orden_id
    WHERE LOWER(eo.nombre) IN ('listo', 'listo_para_recoger', 'ready')
    ORDER BY o.id
    `,
    []
  );
  return (rows || []).map((r: RowDataPacket) => Number(r.id));
};

/**
 * Recalcula subtotal desde ítems y opcionalmente el IVA (16%) según configuración.
 * @param ordenId - ID de la orden
 * @param ivaHabilitado - Si true, impuesto = (subtotal - descuento) * 0.16; si false o no se pasa, se mantiene el impuesto actual (típicamente 0)
 */
export const recalcularTotalesOrden = async (ordenId: number, ivaHabilitado?: boolean) => {
  const [ordenRows] = await pool.query<RowDataPacket[]>(
    `
    SELECT descuento_total, impuesto_total
    FROM orden
    WHERE id = :ordenId
    `,
    { ordenId }
  );
  const orden = ordenRows[0];
  if (!orden) return;

  const [itemsRows] = await pool.query<RowDataPacket[]>(
    `
    SELECT
      oi.id,
      oi.cantidad,
      oi.precio_unitario,
      COALESCE(SUM(oim.precio_unitario), 0) AS modificador_total
    FROM orden_item oi
    LEFT JOIN orden_item_modificador oim ON oim.orden_item_id = oi.id
    WHERE oi.orden_id = :ordenId
    GROUP BY oi.id, oi.cantidad, oi.precio_unitario
    `,
    { ordenId }
  );

  let subtotal = 0;
  for (const row of itemsRows) {
    const cantidad = Number(row.cantidad) || 0;
    const precioUnitario = Number(row.precio_unitario) || 0;
    const modificadorTotal = Number(row.modificador_total) || 0;
    const totalLinea = cantidad * precioUnitario;
    const linea = totalLinea + (modificadorTotal * cantidad);
    subtotal += linea;
    // total_linea es columna generada automáticamente, no necesita actualizarse
  }

  const descuentoTotal = Number(orden.descuento_total ?? 0);
  const baseImponible = subtotal - descuentoTotal;
  const impuestoTotal =
    ivaHabilitado === true
      ? Math.round(baseImponible * 0.16 * 100) / 100
      : Number(orden.impuesto_total ?? 0);
  const total = Math.round((baseImponible + impuestoTotal) * 100) / 100;

  await pool.execute(
    `
    UPDATE orden
    SET subtotal = :subtotal,
        impuesto_total = :impuestoTotal,
        total = :total,
        actualizado_en = NOW()
    WHERE id = :ordenId
    `,
    { subtotal, impuestoTotal, total, ordenId }
  );
};

