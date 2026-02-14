import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool, withTransaction } from '../../db/pool.js';
import { utcToMxISO } from '../../config/time.js';

interface RolRow extends RowDataPacket {
  id: number;
  nombre: string;
  descripcion: string | null;
  creado_en: Date;
  actualizado_en: Date;
  permisos: string | null;
}

const mapPermisos = (permisos: string | null) => {
  if (!permisos) return [];
  return permisos
    .split(',')
    .map((entry) => {
      const [id, nombre] = entry.split('|');
      return { id: Number(id), nombre };
    })
    .filter((permiso) => !Number.isNaN(permiso.id));
};

export const listarRoles = async () => {
  const [rows] = await pool.query<RolRow[]>(
    `
    SELECT
      r.id,
      r.nombre,
      r.descripcion,
      r.creado_en,
      r.actualizado_en,
      GROUP_CONCAT(DISTINCT CONCAT(p.id, '|', p.nombre) ORDER BY p.nombre SEPARATOR ',') AS permisos
    FROM rol r
    LEFT JOIN rol_permiso rp ON rp.rol_id = r.id
    LEFT JOIN permiso p ON p.id = rp.permiso_id
    GROUP BY r.id
    ORDER BY r.nombre
    `
  );

  return rows.map((row) => ({
    id: row.id,
    nombre: row.nombre,
    descripcion: row.descripcion,
    creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null),
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? (row.actualizado_en != null ? (row.actualizado_en as Date).toISOString() : null),
    permisos: mapPermisos(row.permisos)
  }));
};

export const obtenerRolPorId = async (id: number) => {
  const [rows] = await pool.query<RolRow[]>(
    `
    SELECT
      r.id,
      r.nombre,
      r.descripcion,
      r.creado_en,
      r.actualizado_en,
      GROUP_CONCAT(DISTINCT CONCAT(p.id, '|', p.nombre) ORDER BY p.nombre SEPARATOR ',') AS permisos
    FROM rol r
    LEFT JOIN rol_permiso rp ON rp.rol_id = r.id
    LEFT JOIN permiso p ON p.id = rp.permiso_id
    WHERE r.id = :id
    GROUP BY r.id
    `,
    { id }
  );

  const row = rows[0];
  if (!row) return null;

  return {
    id: row.id,
    nombre: row.nombre,
    descripcion: row.descripcion,
    creadoEn: utcToMxISO(row.creado_en) ?? (row.creado_en != null ? (row.creado_en as Date).toISOString() : null),
    actualizadoEn: utcToMxISO(row.actualizado_en) ?? (row.actualizado_en != null ? (row.actualizado_en as Date).toISOString() : null),
    permisos: mapPermisos(row.permisos)
  };
};

export const crearRol = async ({
  nombre,
  descripcion,
  permisos
}: {
  nombre: string;
  descripcion?: string | null;
  permisos: number[];
}) => {
  return withTransaction(async (conn) => {
    const [result] = await conn.execute<ResultSetHeader>(
      `
      INSERT INTO rol (nombre, descripcion)
      VALUES (:nombre, :descripcion)
      `,
      { nombre, descripcion: descripcion ?? null }
    );
    const rolId = result.insertId;

    if (permisos.length > 0) {
      const values = permisos.map((permisoId) => [rolId, permisoId]);
      await conn.query(
        `
        INSERT INTO rol_permiso (rol_id, permiso_id)
        VALUES ?
        `,
        [values]
      );
    }

    return rolId;
  });
};

export const actualizarRol = async (
  id: number,
  { nombre, descripcion, permisos }: { nombre?: string; descripcion?: string | null; permisos?: number[] }
) => {
  return withTransaction(async (conn) => {
    if (nombre !== undefined || descripcion !== undefined) {
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

      if (fields.length > 0) {
        await conn.execute(
          `
          UPDATE rol
          SET ${fields.join(', ')}, actualizado_en = NOW()
          WHERE id = :id
          `,
          params
        );
      }
    }

    if (permisos !== undefined) {
      await conn.execute(
        `
        DELETE FROM rol_permiso
        WHERE rol_id = :id
        `,
        { id }
      );

      if (permisos.length > 0) {
        const values = permisos.map((permisoId) => [id, permisoId]);
        await conn.query(
          `
          INSERT INTO rol_permiso (rol_id, permiso_id)
          VALUES ?
          `,
          [values]
        );
      }
    }
  });
};

export const eliminarRol = async (id: number) => {
  await withTransaction(async (conn) => {
    await conn.execute(
      `
      DELETE FROM rol
      WHERE id = :id
      `,
      { id }
    );
  });
};

export const listarPermisos = async () => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT id, nombre, descripcion
    FROM permiso
    ORDER BY nombre
    `
  );

  return rows.map((row) => ({
    id: row.id as number,
    nombre: row.nombre as string,
    descripcion: row.descripcion as string | null
  }));
};

