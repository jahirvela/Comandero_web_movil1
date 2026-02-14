import type { RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';

export interface VentasReporte {
  ordenId: number;
  folio: string;
  fecha: Date;
  mesaCodigo: string | null;
  clienteNombre: string | null;
  subtotal: number;
  descuentoTotal: number;
  impuestoTotal: number;
  propinaTotal: number;
  total: number;
  formaPago: string;
  cajero: string | null;
}

export interface TopProducto {
  productoId: number;
  productoNombre: string;
  categoriaNombre: string;
  cantidadVendida: number;
  ingresos: number;
}

export interface CorteCaja {
  fecha: Date;
  totalVentas: number;
  totalImpuesto: number;
  totalEfectivo: number;
  totalTarjeta: number;
  totalOtros: number;
  totalPropinas: number;
  numeroOrdenes: number;
  cajero: string | null;
}

export interface InventarioMovimiento {
  fecha: Date;
  itemNombre: string;
  unidad: string;
  tipo: string;
  cantidad: number;
  costoUnitario: number | null;
  motivo: string | null;
  usuario: string | null;
}

/**
 * Obtiene reporte de ventas por rango de fechas
 */
export const obtenerReporteVentas = async (
  fechaInicio: Date,
  fechaFin: Date
): Promise<VentasReporte[]> => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT
      o.id AS orden_id,
      CONCAT('ORD-', LPAD(o.id, 6, '0')) AS folio,
      o.creado_en AS fecha,
      m.codigo AS mesa_codigo,
      o.cliente_nombre,
      o.subtotal,
      o.descuento_total,
      o.impuesto_total,
      COALESCE(SUM(prop.monto), 0) AS propina_total,
      o.total,
      fp.nombre AS forma_pago,
      CONCAT(u.nombre, ' (', u.username, ')') AS cajero
    FROM orden o
    LEFT JOIN mesa m ON m.id = o.mesa_id
    LEFT JOIN pago p ON p.orden_id = o.id AND p.estado = 'aplicado'
    LEFT JOIN forma_pago fp ON fp.id = p.forma_pago_id
    LEFT JOIN propina prop ON prop.orden_id = o.id
    LEFT JOIN usuario u ON u.id = p.empleado_id
    WHERE DATE(o.creado_en) BETWEEN DATE(:fechaInicio) AND DATE(:fechaFin)
      AND o.estado_orden_id IN (
        SELECT id FROM estado_orden WHERE nombre IN ('cerrada', 'pagada')
      )
    GROUP BY o.id, p.id
    ORDER BY o.creado_en DESC
    `,
    { fechaInicio, fechaFin }
  );

  return rows.map((row) => ({
    ordenId: row.orden_id,
    folio: row.folio,
    fecha: row.fecha,
    mesaCodigo: row.mesa_codigo,
    clienteNombre: row.cliente_nombre,
    subtotal: Number(row.subtotal),
    descuentoTotal: Number(row.descuento_total),
    impuestoTotal: Number(row.impuesto_total),
    propinaTotal: Number(row.propina_total),
    total: Number(row.total),
    formaPago: row.forma_pago || 'N/A',
    cajero: row.cajero
  }));
};

/**
 * Obtiene top productos vendidos por rango de fechas
 */
export const obtenerTopProductos = async (
  fechaInicio: Date,
  fechaFin: Date,
  limite: number = 10
): Promise<TopProducto[]> => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT
      COALESCE(p.id, 0) AS producto_id,
      COALESCE(oi.producto_nombre, p.nombre, 'Producto') AS producto_nombre,
      COALESCE(c.nombre, 'Sin categoría') AS categoria_nombre,
      SUM(oi.cantidad) AS cantidad_vendida,
      SUM(oi.total_linea) AS ingresos
    FROM orden_item oi
    LEFT JOIN producto p ON p.id = oi.producto_id
    LEFT JOIN categoria c ON c.id = p.categoria_id
    JOIN orden o ON o.id = oi.orden_id
    WHERE DATE(o.creado_en) BETWEEN DATE(:fechaInicio) AND DATE(:fechaFin)
      AND o.estado_orden_id IN (
        SELECT id FROM estado_orden WHERE nombre IN ('cerrada', 'pagada')
      )
    GROUP BY COALESCE(oi.producto_nombre, p.nombre), COALESCE(c.nombre, 'Sin categoría'), COALESCE(p.id, 0)
    ORDER BY cantidad_vendida DESC
    LIMIT :limite
    `,
    { fechaInicio, fechaFin, limite }
  );

  return rows.map((row) => ({
    productoId: Number(row.producto_id),
    productoNombre: (row.producto_nombre as string) || 'Producto',
    categoriaNombre: (row.categoria_nombre as string) || 'Sin categoría',
    cantidadVendida: Number(row.cantidad_vendida),
    ingresos: Number(row.ingresos)
  }));
};

/**
 * Obtiene corte de caja por fecha
 */
export const obtenerCorteCaja = async (fecha: Date, cajeroId?: number): Promise<CorteCaja> => {
  const conditions: string[] = ['DATE(o.creado_en) = DATE(:fecha)'];
  const params: Record<string, unknown> = { fecha };

  if (cajeroId) {
    conditions.push('p.empleado_id = :cajeroId');
    params.cajeroId = cajeroId;
  }

  const whereClause = conditions.join(' AND ');

  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT
      DATE(o.creado_en) AS fecha,
      COUNT(DISTINCT o.id) AS numero_ordenes,
      SUM(o.total) AS total_ventas,
      COALESCE(SUM(o.impuesto_total), 0) AS total_impuesto,
      SUM(CASE WHEN fp.nombre = 'Efectivo' THEN p.monto ELSE 0 END) AS total_efectivo,
      SUM(CASE WHEN fp.nombre = 'Tarjeta' THEN p.monto ELSE 0 END) AS total_tarjeta,
      SUM(CASE WHEN fp.nombre NOT IN ('Efectivo', 'Tarjeta') THEN p.monto ELSE 0 END) AS total_otros,
      COALESCE(SUM(prop.monto), 0) AS total_propinas,
      CONCAT(u.nombre, ' (', u.username, ')') AS cajero
    FROM orden o
    LEFT JOIN pago p ON p.orden_id = o.id AND p.estado = 'aplicado'
    LEFT JOIN forma_pago fp ON fp.id = p.forma_pago_id
    LEFT JOIN propina prop ON prop.orden_id = o.id
    LEFT JOIN usuario u ON u.id = p.empleado_id
    WHERE ${whereClause}
      AND o.estado_orden_id IN (
        SELECT id FROM estado_orden WHERE nombre IN ('cerrada', 'pagada')
      )
    GROUP BY DATE(o.creado_en), u.id
    `,
    params
  );

  if (rows.length === 0) {
    return {
      fecha,
      totalVentas: 0,
      totalImpuesto: 0,
      totalEfectivo: 0,
      totalTarjeta: 0,
      totalOtros: 0,
      totalPropinas: 0,
      numeroOrdenes: 0,
      cajero: null
    };
  }

  const row = rows[0];
  return {
    fecha: row.fecha,
    totalVentas: Number(row.total_ventas || 0),
    totalImpuesto: Number(row.total_impuesto || 0),
    totalEfectivo: Number(row.total_efectivo || 0),
    totalTarjeta: Number(row.total_tarjeta || 0),
    totalOtros: Number(row.total_otros || 0),
    totalPropinas: Number(row.total_propinas || 0),
    numeroOrdenes: Number(row.numero_ordenes || 0),
    cajero: row.cajero || null
  };
};

/**
 * Obtiene movimientos de inventario por rango de fechas
 */
export const obtenerReporteInventario = async (
  fechaInicio: Date,
  fechaFin: Date
): Promise<InventarioMovimiento[]> => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT
      m.creado_en AS fecha,
      i.nombre AS item_nombre,
      i.unidad,
      m.tipo,
      m.cantidad,
      m.costo_unitario,
      m.motivo,
      CONCAT(u.nombre, ' (', u.username, ')') AS usuario
    FROM movimiento_inventario m
    JOIN inventario_item i ON i.id = m.inventario_item_id
    LEFT JOIN usuario u ON u.id = m.creado_por_usuario_id
    WHERE DATE(m.creado_en) BETWEEN DATE(:fechaInicio) AND DATE(:fechaFin)
    ORDER BY m.creado_en DESC
    `,
    { fechaInicio, fechaFin }
  );

  return rows.map((row) => ({
    fecha: row.fecha,
    itemNombre: row.item_nombre,
    unidad: row.unidad,
    tipo: row.tipo,
    cantidad: Number(row.cantidad),
    costoUnitario: row.costo_unitario === null ? null : Number(row.costo_unitario),
    motivo: row.motivo,
    usuario: row.usuario
  }));
};

