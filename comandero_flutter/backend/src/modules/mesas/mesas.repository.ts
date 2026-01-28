import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool, withTransaction } from '../../db/pool.js';

interface MesaRow extends RowDataPacket {
  id: number;
  codigo: string;
  nombre: string | null;
  capacidad: number | null;
  ubicacion: string | null;
  estado_mesa_id: number | null;
  estado_nombre: string | null;
  activo: number;
  creado_en: Date;
  actualizado_en: Date;
}

interface EstadoMesaRow extends RowDataPacket {
  id: number;
  nombre: string;
  descripcion: string | null;
}

interface HistorialRow extends RowDataPacket {
  id: number;
  estado_mesa_id: number;
  estado_nombre: string;
  cambiado_por_usuario_id: number | null;
  nota: string | null;
  cambiado_en: Date;
}

export const listarMesas = async () => {
  const [rows] = await pool.query<MesaRow[]>(
    `
    SELECT
      m.*,
      em.nombre AS estado_nombre
    FROM mesa m
    LEFT JOIN estado_mesa em ON em.id = m.estado_mesa_id
    WHERE m.activo = 1
    ORDER BY m.codigo
    `
  );

  return rows.map((row) => ({
    id: row.id,
    codigo: row.codigo,
    nombre: row.nombre,
    capacidad: row.capacidad,
    ubicacion: row.ubicacion,
    estadoMesaId: row.estado_mesa_id,
    estadoNombre: row.estado_nombre,
    activo: Boolean(row.activo),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en
  }));
};

export const obtenerMesaPorId = async (id: number) => {
  const [rows] = await pool.query<MesaRow[]>(
    `
    SELECT
      m.*,
      em.nombre AS estado_nombre
    FROM mesa m
    LEFT JOIN estado_mesa em ON em.id = m.estado_mesa_id
    WHERE m.id = :id AND m.activo = 1
    `,
    { id }
  );
  const row = rows[0];
  if (!row) return null;
  return {
    id: row.id,
    codigo: row.codigo,
    nombre: row.nombre,
    capacidad: row.capacidad,
    ubicacion: row.ubicacion,
    estadoMesaId: row.estado_mesa_id,
    estadoNombre: row.estado_nombre,
    activo: Boolean(row.activo),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en
  };
};

export const obtenerMesaPorCodigo = async (codigo: string) => {
  const [rows] = await pool.query<MesaRow[]>(
    `
    SELECT
      m.*,
      em.nombre AS estado_nombre
    FROM mesa m
    LEFT JOIN estado_mesa em ON em.id = m.estado_mesa_id
    WHERE m.codigo = :codigo AND m.activo = 1
    `,
    { codigo }
  );
  const row = rows[0];
  if (!row) return null;
  return {
    id: row.id,
    codigo: row.codigo,
    nombre: row.nombre,
    capacidad: row.capacidad,
    ubicacion: row.ubicacion,
    estadoMesaId: row.estado_mesa_id,
    estadoNombre: row.estado_nombre,
    activo: Boolean(row.activo),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en
  };
};

export const obtenerMesaPorCodigoIncluyendoInactivos = async (codigo: string) => {
  const [rows] = await pool.query<MesaRow[]>(
    `
    SELECT
      m.*,
      em.nombre AS estado_nombre
    FROM mesa m
    LEFT JOIN estado_mesa em ON em.id = m.estado_mesa_id
    WHERE m.codigo = :codigo
    `,
    { codigo }
  );
  const row = rows[0];
  if (!row) return null;
  return {
    id: row.id,
    codigo: row.codigo,
    nombre: row.nombre,
    capacidad: row.capacidad,
    ubicacion: row.ubicacion,
    estadoMesaId: row.estado_mesa_id,
    estadoNombre: row.estado_nombre,
    activo: Boolean(row.activo),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en
  };
};

export const crearMesa = async ({
  codigo,
  nombre,
  capacidad,
  ubicacion,
  estadoMesaId,
  activo
}: {
  codigo: string;
  nombre?: string | null;
  capacidad?: number | null;
  ubicacion?: string | null;
  estadoMesaId?: number | null;
  activo: boolean;
}) => {
  const [result] = await pool.execute<ResultSetHeader>(
    `
    INSERT INTO mesa (codigo, nombre, capacidad, ubicacion, estado_mesa_id, activo)
    VALUES (:codigo, :nombre, :capacidad, :ubicacion, :estadoMesaId, :activo)
    `,
    {
      codigo,
      nombre: nombre ?? null,
      capacidad: capacidad ?? null,
      ubicacion: ubicacion ?? null,
      estadoMesaId: estadoMesaId ?? null,
      activo: activo ? 1 : 0
    }
  );
  return result.insertId;
};

export const actualizarMesa = async (
  id: number,
  {
    codigo,
    nombre,
    capacidad,
    ubicacion,
    estadoMesaId,
    activo
  }: {
    codigo?: string;
    nombre?: string | null;
    capacidad?: number | null;
    ubicacion?: string | null;
    estadoMesaId?: number | null;
    activo?: boolean;
  }
) => {
  const fields: string[] = [];
  const params: Record<string, unknown> = { id };

  if (codigo !== undefined) {
    fields.push('codigo = :codigo');
    params.codigo = codigo;
  }
  if (nombre !== undefined) {
    fields.push('nombre = :nombre');
    params.nombre = nombre ?? null;
  }
  if (capacidad !== undefined) {
    fields.push('capacidad = :capacidad');
    params.capacidad = capacidad ?? null;
  }
  if (ubicacion !== undefined) {
    fields.push('ubicacion = :ubicacion');
    params.ubicacion = ubicacion ?? null;
  }
  if (estadoMesaId !== undefined) {
    fields.push('estado_mesa_id = :estadoMesaId');
    params.estadoMesaId = estadoMesaId ?? null;
  }
  if (activo !== undefined) {
    fields.push('activo = :activo');
    params.activo = activo ? 1 : 0;
  }

  if (fields.length === 0) return;

  await pool.execute(
    `
    UPDATE mesa
    SET ${fields.join(', ')}, actualizado_en = NOW()
    WHERE id = :id
    `,
    params
  );
};

export const eliminarMesa = async (id: number) => {
  await pool.execute(
    `
    UPDATE mesa
    SET activo = 0, actualizado_en = NOW()
    WHERE id = :id
    `,
    { id }
  );
};

export const cambiarEstadoMesa = async ({
  mesaId,
  estadoMesaId,
  usuarioId,
  nota
}: {
  mesaId: number;
  estadoMesaId: number;
  usuarioId?: number | null;
  nota?: string | null;
}) => {
  await withTransaction(async (conn) => {
    await conn.execute(
      `
      UPDATE mesa
      SET estado_mesa_id = :estadoMesaId, actualizado_en = NOW()
      WHERE id = :mesaId
      `,
      { mesaId, estadoMesaId }
    );

    await conn.execute(
      `
      INSERT INTO mesa_estado_hist (mesa_id, estado_mesa_id, cambiado_por_usuario_id, nota)
      VALUES (:mesaId, :estadoMesaId, :usuarioId, :nota)
      `,
      {
        mesaId,
        estadoMesaId,
        usuarioId: usuarioId ?? null,
        nota: nota ?? null
      }
    );
  });
};

export const obtenerHistorialMesa = async (mesaId: number) => {
  const [rows] = await pool.query<HistorialRow[]>(
    `
    SELECT
      h.id,
      h.estado_mesa_id,
      em.nombre AS estado_nombre,
      h.cambiado_por_usuario_id,
      h.nota,
      h.cambiado_en
    FROM mesa_estado_hist h
    JOIN estado_mesa em ON em.id = h.estado_mesa_id
    WHERE h.mesa_id = :mesaId
    ORDER BY h.cambiado_en DESC
    `,
    { mesaId }
  );

  return rows.map((row) => ({
    id: row.id,
    estadoMesaId: row.estado_mesa_id,
    estadoNombre: row.estado_nombre,
    cambiadoPorUsuarioId: row.cambiado_por_usuario_id,
    nota: row.nota,
    cambiadoEn: row.cambiado_en
  }));
};

export const listarEstadosMesa = async () => {
  const [rows] = await pool.query<EstadoMesaRow[]>(
    `
    SELECT id, nombre, descripcion
    FROM estado_mesa
    ORDER BY id
    `
  );
  return rows.map((row) => ({
    id: row.id,
    nombre: row.nombre,
    descripcion: row.descripcion
  }));
};

