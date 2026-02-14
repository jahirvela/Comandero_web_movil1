import { pool } from '../db/pool.js';
import type { UserWithRoles } from './auth.types.js';

interface UserRow {
  id: number;
  nombre: string;
  username: string;
  password_hash: string;
  activo: number;
  ultimo_acceso: Date | null;
  rol_nombre: string | null;
}

const mapRowsToUser = (rows: UserRow[]): UserWithRoles | null => {
  if (rows.length === 0) {
    return null;
  }

  const base = rows[0];
  const roles = Array.from(
    new Set(rows.filter((row) => row.rol_nombre).map((row) => row.rol_nombre as string))
  );

  return {
    id: base.id,
    nombre: base.nombre,
    username: base.username,
    passwordHash: base.password_hash,
    activo: Boolean(base.activo),
    ultimoAcceso: base.ultimo_acceso,
    roles
  };
};

export const findUserByUsername = async (username: string) => {
  try {
    // Intentar consulta con roles primero
    const [rows] = await pool.query(
      `
      SELECT
        u.id,
        u.nombre,
        u.username,
        u.password_hash,
        u.activo,
        u.ultimo_acceso,
        r.nombre AS rol_nombre
      FROM usuario u
      LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
      LEFT JOIN rol r ON r.id = ur.rol_id
      WHERE u.username = :username
      `,
      { username }
    );

    return mapRowsToUser(rows as UserRow[]);
  } catch (error: any) {
    // Si las tablas de roles no existen, hacer consulta simple
    if (error.code === 'ER_NO_SUCH_TABLE' || error.message?.includes("doesn't exist")) {
      const [rows] = await pool.query(
        `
        SELECT
          u.id,
          u.nombre,
          u.username,
          u.password_hash,
          u.activo,
          u.ultimo_acceso,
          NULL AS rol_nombre
        FROM usuario u
        WHERE u.username = :username
        `,
        { username }
      );

      return mapRowsToUser(rows as UserRow[]);
    }
    throw error;
  }
};

export const findUserById = async (id: number) => {
  try {
    // Intentar consulta con roles primero
    const [rows] = await pool.query(
      `
      SELECT
        u.id,
        u.nombre,
        u.username,
        u.password_hash,
        u.activo,
        u.ultimo_acceso,
        r.nombre AS rol_nombre
      FROM usuario u
      LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
      LEFT JOIN rol r ON r.id = ur.rol_id
      WHERE u.id = :id
      `,
      { id }
    );

    return mapRowsToUser(rows as UserRow[]);
  } catch (error: any) {
    // Si las tablas de roles no existen, hacer consulta simple
    if (error.code === 'ER_NO_SUCH_TABLE' || error.message?.includes("doesn't exist")) {
      const [rows] = await pool.query(
        `
        SELECT
          u.id,
          u.nombre,
          u.username,
          u.password_hash,
          u.activo,
          u.ultimo_acceso,
          NULL AS rol_nombre
        FROM usuario u
        WHERE u.id = :id
        `,
        { id }
      );

      return mapRowsToUser(rows as UserRow[]);
    }
    throw error;
  }
};

export const actualizarUltimoAcceso = async (id: number) => {
  await pool.query(
    `
    UPDATE usuario
    SET ultimo_acceso = NOW()
    WHERE id = :id
    `,
    { id }
  );
};

