import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';
import { utcToMxISO } from '../../config/time.js';

interface PagoRow extends RowDataPacket {
  id: number;
  orden_id: number;
  forma_pago_id: number;
  forma_pago_nombre: string;
  monto: number;
  referencia: string | null;
  estado: string;
  fecha_pago: Date;
  empleado_id: number | null;
  creado_en: Date;
  actualizado_en: Date;
}

interface PropinaRow extends RowDataPacket {
  id: number;
  orden_id: number;
  monto: number;
  registrado_por_usuario_id: number | null;
  fecha: Date;
}

export const listarPagos = async (ordenId?: number) => {
  const [rows] = await pool.query<PagoRow[]>(
    `
    SELECT
      p.*,
      fp.nombre AS forma_pago_nombre
    FROM pago p
    JOIN forma_pago fp ON fp.id = p.forma_pago_id
    ${ordenId ? 'WHERE p.orden_id = :ordenId' : ''}
    ORDER BY p.fecha_pago DESC
    `,
    ordenId ? { ordenId } : undefined
  );

  return rows.map((row) => ({
    id: row.id,
    ordenId: row.orden_id,
    formaPagoId: row.forma_pago_id,
    formaPagoNombre: row.forma_pago_nombre,
    monto: Number(row.monto),
    referencia: row.referencia,
    estado: row.estado,
    fechaPago: utcToMxISO(row.fecha_pago) ?? row.fecha_pago.toISOString(),
    empleadoId: row.empleado_id,
    creadoEn: utcToMxISO(row.creado_en) ?? row.creado_en.toISOString(),
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? row.actualizado_en.toISOString()
  }));
};

export const obtenerPagoPorId = async (id: number) => {
  const [rows] = await pool.query<PagoRow[]>(
    `
    SELECT
      p.*,
      fp.nombre AS forma_pago_nombre
    FROM pago p
    JOIN forma_pago fp ON fp.id = p.forma_pago_id
    WHERE p.id = :id
    `,
    { id }
  );

  const row = rows[0];
  if (!row) return null;

  return {
    id: row.id,
    ordenId: row.orden_id,
    formaPagoId: row.forma_pago_id,
    formaPagoNombre: row.forma_pago_nombre,
    monto: Number(row.monto),
    referencia: row.referencia,
    estado: row.estado,
    fechaPago: utcToMxISO(row.fecha_pago) ?? row.fecha_pago.toISOString(),
    empleadoId: row.empleado_id,
    creadoEn: utcToMxISO(row.creado_en) ?? row.creado_en.toISOString(),
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? row.actualizado_en.toISOString()
  };
};

export const crearPago = async ({
  ordenId,
  formaPagoId,
  monto,
  referencia,
  estado,
  fechaPago,
  empleadoId
}: {
  ordenId: number;
  formaPagoId: number;
  monto: number;
  referencia?: string | null;
  estado: 'aplicado' | 'anulado' | 'pendiente';
  fechaPago?: string | null;
  empleadoId?: number | null;
}) => {
  const [result] = await pool.execute<ResultSetHeader>(
    `
    INSERT INTO pago (
      orden_id,
      forma_pago_id,
      monto,
      referencia,
      estado,
      fecha_pago,
      empleado_id
    )
    VALUES (
      :ordenId,
      :formaPagoId,
      :monto,
      :referencia,
      :estado,
      COALESCE(:fechaPago, NOW()),
      :empleadoId
    )
    `,
    {
      ordenId,
      formaPagoId,
      monto,
      referencia: referencia ?? null,
      estado,
      fechaPago: fechaPago ?? null,
      empleadoId: empleadoId ?? null
    }
  );
  return result.insertId;
};

export const listarPropinas = async (ordenId?: number) => {
  const [rows] = await pool.query<PropinaRow[]>(
    `
    SELECT *
    FROM propina
    ${ordenId ? 'WHERE orden_id = :ordenId' : ''}
    ORDER BY fecha DESC
    `,
    ordenId ? { ordenId } : undefined
  );

  return rows.map((row) => ({
    id: row.id,
    ordenId: row.orden_id,
    monto: Number(row.monto),
    registradoPorUsuarioId: row.registrado_por_usuario_id,
    fecha: row.fecha
  }));
};

export const registrarPropina = async ({
  ordenId,
  monto,
  usuarioId
}: {
  ordenId: number;
  monto: number;
  usuarioId?: number | null;
}) => {
  const [result] = await pool.execute<ResultSetHeader>(
    `
    INSERT INTO propina (orden_id, monto, registrado_por_usuario_id)
    VALUES (:ordenId, :monto, :usuarioId)
    `,
    {
      ordenId,
      monto,
      usuarioId: usuarioId ?? null
    }
  );
  return result.insertId;
};

export const listarFormasPago = async () => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT id, nombre, descripcion
    FROM forma_pago
    ORDER BY id
    `
  );
  return rows.map((row) => ({
    id: row.id as number,
    nombre: row.nombre as string,
    descripcion: row.descripcion as string | null
  }));
};

export const obtenerTotalPagado = async (ordenId: number) => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT COALESCE(SUM(monto), 0) AS total
    FROM pago
    WHERE orden_id = :ordenId
      AND estado = 'aplicado'
    `,
    { ordenId }
  );
  return Number(rows[0]?.total ?? 0);
};

