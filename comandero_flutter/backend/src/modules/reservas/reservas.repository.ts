import type { RowDataPacket, ResultSetHeader } from 'mysql2';
import { pool, withTransaction } from '../../db/pool.js';
import { utcToMx } from '../../config/time.js';

interface ReservaRow extends RowDataPacket {
  id: number;
  mesa_id: number;
  nombre_cliente: string | null;
  telefono: string | null;
  fecha_hora_inicio: Date;
  fecha_hora_fin: Date | null;
  estado: string;
  creado_por_usuario_id: number | null;
  creado_en: Date;
  actualizado_en: Date;
  mesa_numero: number | null;
  usuario_nombre: string | null;
}

export interface ReservaItem {
  id: number;
  mesaId: number;
  mesaNumero: number | null;
  nombreCliente: string | null;
  telefono: string | null;
  fechaHoraInicio: Date;
  fechaHoraFin: Date | null;
  estado: string;
  creadoPorUsuarioId: number | null;
  creadoPorUsuarioNombre: string | null;
  creadoEn: Date;
  actualizadoEn: Date;
}

export const listarReservas = async (
  mesaId?: number,
  fechaInicio?: Date,
  fechaFin?: Date,
  estado?: string
): Promise<ReservaItem[]> => {
  const conditions: string[] = [];
  const params: Record<string, unknown> = {};

  if (mesaId) {
    conditions.push('r.mesa_id = :mesaId');
    params.mesaId = mesaId;
  }

  if (fechaInicio) {
    conditions.push('DATE(r.fecha_hora_inicio) >= DATE(:fechaInicio)');
    params.fechaInicio = fechaInicio;
  }

  if (fechaFin) {
    conditions.push('DATE(r.fecha_hora_inicio) <= DATE(:fechaFin)');
    params.fechaFin = fechaFin;
  }

  if (estado) {
    conditions.push('r.estado = :estado');
    params.estado = estado;
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  const [rows] = await pool.query<ReservaRow[]>(
    `
    SELECT
      r.id,
      r.mesa_id,
      m.codigo AS mesa_numero,
      r.nombre_cliente,
      r.telefono,
      r.fecha_hora_inicio,
      r.fecha_hora_fin,
      r.estado,
      r.creado_por_usuario_id,
      u.nombre AS usuario_nombre,
      r.creado_en,
      r.actualizado_en
    FROM reserva r
    LEFT JOIN mesa m ON m.id = r.mesa_id
    LEFT JOIN usuario u ON u.id = r.creado_por_usuario_id
    ${whereClause}
    ORDER BY r.fecha_hora_inicio ASC, r.creado_en DESC
    `,
    params
  );

  return rows.map((row) => ({
    id: row.id,
    mesaId: row.mesa_id,
    mesaNumero: row.mesa_numero,
    nombreCliente: row.nombre_cliente,
    telefono: row.telefono,
    // Convertir fechas UTC de BD a zona CDMX
    fechaHoraInicio: utcToMx(row.fecha_hora_inicio)?.toJSDate() ?? new Date(row.fecha_hora_inicio),
    fechaHoraFin: row.fecha_hora_fin ? (utcToMx(row.fecha_hora_fin)?.toJSDate() ?? new Date(row.fecha_hora_fin)) : null,
    estado: row.estado,
    creadoPorUsuarioId: row.creado_por_usuario_id,
    creadoPorUsuarioNombre: row.usuario_nombre,
    creadoEn: utcToMx(row.creado_en)?.toJSDate() ?? new Date(row.creado_en),
    actualizadoEn: utcToMx(row.actualizado_en)?.toJSDate() ?? new Date(row.actualizado_en),
  }));
};

export const obtenerReservaPorId = async (id: number): Promise<ReservaItem | null> => {
  const [rows] = await pool.query<ReservaRow[]>(
    `
    SELECT
      r.id,
      r.mesa_id,
      m.codigo AS mesa_numero,
      r.nombre_cliente,
      r.telefono,
      r.fecha_hora_inicio,
      r.fecha_hora_fin,
      r.estado,
      r.creado_por_usuario_id,
      u.nombre AS usuario_nombre,
      r.creado_en,
      r.actualizado_en
    FROM reserva r
    LEFT JOIN mesa m ON m.id = r.mesa_id
    LEFT JOIN usuario u ON u.id = r.creado_por_usuario_id
    WHERE r.id = :id
    `,
    { id }
  );

  if (rows.length === 0) return null;

  const row = rows[0];
  return {
    id: row.id,
    mesaId: row.mesa_id,
    mesaNumero: row.mesa_numero,
    nombreCliente: row.nombre_cliente,
    telefono: row.telefono,
    // Convertir fechas UTC de BD a zona CDMX
    fechaHoraInicio: utcToMx(row.fecha_hora_inicio)?.toJSDate() ?? new Date(row.fecha_hora_inicio),
    fechaHoraFin: row.fecha_hora_fin ? (utcToMx(row.fecha_hora_fin)?.toJSDate() ?? new Date(row.fecha_hora_fin)) : null,
    estado: row.estado,
    creadoPorUsuarioId: row.creado_por_usuario_id,
    creadoPorUsuarioNombre: row.usuario_nombre,
    creadoEn: utcToMx(row.creado_en)?.toJSDate() ?? new Date(row.creado_en),
    actualizadoEn: utcToMx(row.actualizado_en)?.toJSDate() ?? new Date(row.actualizado_en),
  };
};

export const crearReserva = async (
  input: {
    mesaId: number;
    nombreCliente?: string | null;
    telefono?: string | null;
    fechaHoraInicio: Date;
    fechaHoraFin?: Date | null;
    estado: string;
    creadoPorUsuarioId?: number | null;
  }
): Promise<number> => {
  const [result] = await pool.execute<ResultSetHeader>(
    `
    INSERT INTO reserva (
      mesa_id,
      nombre_cliente,
      telefono,
      fecha_hora_inicio,
      fecha_hora_fin,
      estado,
      creado_por_usuario_id
    )
    VALUES (
      :mesaId,
      :nombreCliente,
      :telefono,
      :fechaHoraInicio,
      :fechaHoraFin,
      :estado,
      :creadoPorUsuarioId
    )
    `,
    {
      mesaId: input.mesaId,
      nombreCliente: input.nombreCliente ?? null,
      telefono: input.telefono ?? null,
      fechaHoraInicio: input.fechaHoraInicio,
      fechaHoraFin: input.fechaHoraFin ?? null,
      estado: input.estado,
      creadoPorUsuarioId: input.creadoPorUsuarioId ?? null,
    }
  );

  return result.insertId;
};

export const actualizarReserva = async (
  id: number,
  input: {
    mesaId?: number;
    nombreCliente?: string | null;
    telefono?: string | null;
    fechaHoraInicio?: Date;
    fechaHoraFin?: Date | null;
    estado?: string;
  }
): Promise<void> => {
  const fields: string[] = [];
  const params: Record<string, unknown> = { id };

  if (input.mesaId !== undefined) {
    fields.push('mesa_id = :mesaId');
    params.mesaId = input.mesaId;
  }

  if (input.nombreCliente !== undefined) {
    fields.push('nombre_cliente = :nombreCliente');
    params.nombreCliente = input.nombreCliente;
  }

  if (input.telefono !== undefined) {
    fields.push('telefono = :telefono');
    params.telefono = input.telefono;
  }

  if (input.fechaHoraInicio !== undefined) {
    fields.push('fecha_hora_inicio = :fechaHoraInicio');
    params.fechaHoraInicio = input.fechaHoraInicio;
  }

  if (input.fechaHoraFin !== undefined) {
    fields.push('fecha_hora_fin = :fechaHoraFin');
    params.fechaHoraFin = input.fechaHoraFin;
  }

  if (input.estado !== undefined) {
    fields.push('estado = :estado');
    params.estado = input.estado;
  }

  if (fields.length === 0) {
    return; // No hay nada que actualizar
  }

  await pool.execute(
    `
    UPDATE reserva
    SET ${fields.join(', ')}
    WHERE id = :id
    `,
    params
  );
};

export const eliminarReserva = async (id: number): Promise<void> => {
  await pool.execute(
    `
    DELETE FROM reserva
    WHERE id = :id
    `,
    { id }
  );
};

