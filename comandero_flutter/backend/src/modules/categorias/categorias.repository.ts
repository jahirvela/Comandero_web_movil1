import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';

interface CategoriaRow extends RowDataPacket {
  id: number;
  nombre: string;
  descripcion: string | null;
  activo: number;
  creado_en: Date;
  actualizado_en: Date;
}

export const listarCategorias = async () => {
  const [rows] = await pool.query<CategoriaRow[]>(
    `
    SELECT *
    FROM categoria
    ORDER BY nombre
    `
  );
  return rows.map((row) => ({
    id: row.id,
    nombre: row.nombre,
    descripcion: row.descripcion,
    activo: Boolean(row.activo),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en
  }));
};

export const obtenerCategoriaPorId = async (id: number) => {
  const [rows] = await pool.query<CategoriaRow[]>(
    `
    SELECT *
    FROM categoria
    WHERE id = :id
    `,
    { id }
  );
  const row = rows[0];
  if (!row) return null;
  return {
    id: row.id,
    nombre: row.nombre,
    descripcion: row.descripcion,
    activo: Boolean(row.activo),
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en
  };
};

export const crearCategoria = async ({
  nombre,
  descripcion,
  activo
}: {
  nombre: string;
  descripcion?: string | null;
  activo: boolean;
}) => {
  const [result] = await pool.execute<ResultSetHeader>(
    `
    INSERT INTO categoria (nombre, descripcion, activo)
    VALUES (:nombre, :descripcion, :activo)
    `,
    {
      nombre,
      descripcion: descripcion ?? null,
      activo: activo ? 1 : 0
    }
  );
  return result.insertId;
};

export const actualizarCategoria = async (
  id: number,
  {
    nombre,
    descripcion,
    activo
  }: {
    nombre?: string;
    descripcion?: string | null;
    activo?: boolean;
  }
) => {
  const fields: string[] = [];
  const params: Record<string, unknown> = { id };

  if (nombre !== undefined) {
    fields.push('nombre = :nombre');
    params.nombre = nombre;
  }

  if (descripcion !== undefined) {
    fields.push('descripcion = :descripcion');
    params.descripcion = descripcion ?? null;
  }

  if (activo !== undefined) {
    fields.push('activo = :activo');
    params.activo = activo ? 1 : 0;
  }

  if (fields.length === 0) return;

  await pool.execute(
    `
    UPDATE categoria
    SET ${fields.join(', ')}, actualizado_en = NOW()
    WHERE id = :id
    `,
    params
  );
};

export const eliminarCategoria = async (id: number) => {
  await pool.execute(
    `
    UPDATE categoria
    SET activo = 0, actualizado_en = NOW()
    WHERE id = :id
    `,
    { id }
  );
};

