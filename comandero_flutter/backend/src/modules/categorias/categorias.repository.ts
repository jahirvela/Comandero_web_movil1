import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';
import { utcToMxISO } from '../../config/time.js';
import { withTransaction } from '../../db/pool.js';

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
    WHERE activo = 1
    ORDER BY nombre
    `
  );
  return rows.map((row) => ({
    id: row.id,
    nombre: row.nombre,
    descripcion: row.descripcion,
    activo: Boolean(row.activo),
    creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null),
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? (row.actualizado_en != null ? (row.actualizado_en as Date).toISOString() : null)
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
    creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null),
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? (row.actualizado_en != null ? (row.actualizado_en as Date).toISOString() : null)
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
  await withTransaction(async (conn) => {
    const [categoriaRows] = await conn.query<CategoriaRow[]>(
      `
      SELECT id, nombre, activo, descripcion, creado_en, actualizado_en
      FROM categoria
      WHERE id = :id
      LIMIT 1
      `,
      { id }
    );
    const categoria = categoriaRows[0];
    if (!categoria) return;

    const nombreRespaldo = 'Otros';
    let categoriaRespaldoId: number;
    const [respaldoRows] = await conn.query<CategoriaRow[]>(
      `
      SELECT id, nombre, descripcion, activo, creado_en, actualizado_en
      FROM categoria
      WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(:nombreRespaldo))
      LIMIT 1
      `,
      { nombreRespaldo }
    );

    if (respaldoRows.length > 0) {
      categoriaRespaldoId = respaldoRows[0].id;
      if (!respaldoRows[0].activo) {
        await conn.execute(
          `
          UPDATE categoria
          SET activo = 1, actualizado_en = NOW()
          WHERE id = :id
          `,
          { id: categoriaRespaldoId }
        );
      }
    } else {
      const [insertRespaldo] = await conn.execute<ResultSetHeader>(
        `
        INSERT INTO categoria (nombre, descripcion, activo)
        VALUES (:nombre, :descripcion, 1)
        `,
        { nombre: nombreRespaldo, descripcion: 'Categoría de respaldo automática' }
      );
      categoriaRespaldoId = insertRespaldo.insertId;
    }

    if (categoriaRespaldoId !== id) {
      await conn.execute(
        `
        UPDATE producto
        SET categoria_id = :categoriaRespaldoId, actualizado_en = NOW()
        WHERE categoria_id = :id
        `,
        { categoriaRespaldoId, id }
      );
    }

    await conn.execute(
      `
      UPDATE categoria
      SET activo = 0, actualizado_en = NOW()
      WHERE id = :id
      `,
      { id }
    );
  });
};

