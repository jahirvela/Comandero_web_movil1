import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { withTransaction, pool } from '../../db/pool.js';

interface UsuarioRow extends RowDataPacket {
  id: number;
  nombre: string;
  username: string;
  telefono: string | null;
  activo: number;
  ultimo_acceso: Date | null;
  creado_en: Date;
  actualizado_en: Date;
  roles: string | null;
}

interface UsuarioDetalleRow extends RowDataPacket {
  id: number;
  nombre: string;
  username: string;
  telefono: string | null;
  password_hash: string;
  activo: number;
  ultimo_acceso: Date | null;
  creado_en: Date;
  actualizado_en: Date;
  password_actualizada_en: Date | null;
  roles: string | null;
}

const mapRoles = (roles: string | null) => {
  if (!roles) return [];
  return roles.split(',').map((role) => role.trim()).filter(Boolean);
};

export const listarUsuarios = async () => {
  const [rows] = await pool.query<any[]>(
    `
    SELECT
      u.id,
      u.nombre,
      u.username,
      u.telefono,
      u.activo,
      u.ultimo_acceso,
      u.creado_en,
      u.actualizado_en,
      u.password,
      GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ',') AS roles
    FROM usuario u
    LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
    LEFT JOIN rol r ON r.id = ur.rol_id
    GROUP BY u.id
    ORDER BY u.id DESC
    `
  );

  return rows.map((row) => ({
    id: row.id,
    nombre: row.nombre,
    username: row.username,
    telefono: row.telefono,
    activo: Boolean(row.activo),
    ultimoAcceso: row.ultimo_acceso,
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en,
    password: row.password || '', // Contraseña en texto plano (solo para administrador)
    roles: mapRoles(row.roles)
  }));
};

export const obtenerUsuarioPorId = async (id: number) => {
  const [rows] = await pool.query<any[]>(
    `
    SELECT
      u.*,
      GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ',') AS roles
    FROM usuario u
    LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
    LEFT JOIN rol r ON r.id = ur.rol_id
    WHERE u.id = :id
    GROUP BY u.id
    `,
    { id }
  );

  const row = rows[0];

  if (!row) return null;

  return {
    id: row.id,
    nombre: row.nombre,
    username: row.username,
    telefono: row.telefono,
    passwordHash: row.password_hash,
    password: row.password || '', // Contraseña en texto plano (solo para administrador)
    activo: Boolean(row.activo),
    ultimoAcceso: row.ultimo_acceso,
    creadoEn: row.creado_en,
    actualizadoEn: row.actualizado_en,
    passwordActualizadaEn: row.password_actualizada_en,
    roles: mapRoles(row.roles)
  };
};

export const crearUsuario = async ({
  nombre,
  username,
  telefono,
  passwordHash,
  passwordPlain,
  activo,
  roles,
  actualizadoPor
}: {
  nombre: string;
  username: string;
  telefono?: string | null;
  passwordHash: string;
  passwordPlain?: string;
  activo: boolean;
  roles: number[];
  actualizadoPor?: number | null;
}) => {
  return withTransaction(async (conn) => {
    // Construir la consulta dinámicamente para incluir password si está disponible
    const fields = [
      'nombre',
      'username',
      'telefono',
      'password_hash',
      'activo',
      'password_actualizada_en',
      'password_actualizada_por_usuario_id'
    ];
    
    const values = [
      ':nombre',
      ':username',
      ':telefono',
      ':passwordHash',
      ':activo',
      'NOW()',
      ':actualizadoPor'
    ];
    
    const params: Record<string, unknown> = {
      nombre,
      username,
      telefono: telefono ?? null,
      passwordHash,
      activo: activo ? 1 : 0,
      actualizadoPor: actualizadoPor ?? null
    };
    
    // Incluir password si passwordPlain está definido
    if (passwordPlain !== undefined && passwordPlain !== null) {
      fields.push('password');
      values.push(':passwordPlain');
      params.passwordPlain = passwordPlain;
    }
    
    const [result] = await conn.execute<ResultSetHeader>(
      `
      INSERT INTO usuario (
        ${fields.join(', ')}
      )
      VALUES (${values.join(', ')})
      `,
      params
    );

    const usuarioId = result.insertId;

    if (roles.length > 0) {
      const values = roles.map((rolId) => [usuarioId, rolId]);
      await conn.query(
        `
        INSERT INTO usuario_rol (usuario_id, rol_id)
        VALUES ?
        `,
        [values]
      );
    }

    return usuarioId;
  });
};

export const actualizarUsuario = async (
  id: number,
  {
    nombre,
    telefono,
    activo,
    passwordHash,
    passwordPlain,
    roles,
    actualizadoPor
  }: {
    nombre?: string;
    telefono?: string | null;
    activo?: boolean;
    passwordHash?: string;
    passwordPlain?: string;
    roles?: number[];
    actualizadoPor?: number | null;
  }
) => {
  return withTransaction(async (conn) => {
    if (nombre !== undefined || telefono !== undefined || activo !== undefined || passwordHash) {
      const fields: string[] = [];
      const params: Record<string, unknown> = { id };

      if (nombre !== undefined) {
        fields.push('nombre = :nombre');
        params.nombre = nombre;
      }

      if (telefono !== undefined) {
        fields.push('telefono = :telefono');
        params.telefono = telefono ?? null;
      }

      if (activo !== undefined) {
        fields.push('activo = :activo');
        params.activo = activo ? 1 : 0;
      }

      if (passwordHash) {
        fields.push('password_hash = :passwordHash');
        fields.push('password_actualizada_en = NOW()');
        fields.push('password_actualizada_por_usuario_id = :actualizadoPor');
        params.passwordHash = passwordHash;
        params.actualizadoPor = actualizadoPor ?? null;
        
        // Si se proporciona passwordPlain, también guardarlo en texto plano
        if (passwordPlain !== undefined) {
          fields.push('password = :passwordPlain');
          params.passwordPlain = passwordPlain;
        }
      }

      if (fields.length > 0) {
        await conn.execute(
          `
          UPDATE usuario
          SET ${fields.join(', ')}, actualizado_en = NOW()
          WHERE id = :id
          `,
          params
        );
      }
    }

    if (roles !== undefined) {
      await conn.execute(
        `
        DELETE FROM usuario_rol
        WHERE usuario_id = :id
        `,
        { id }
      );

      if (roles.length > 0) {
        const values = roles.map((rolId) => [id, rolId]);
        await conn.query(
          `
          INSERT INTO usuario_rol (usuario_id, rol_id)
          VALUES ?
          `,
          [values]
        );
      }
    }
  });
};

export const eliminarUsuario = async (id: number) => {
  await pool.execute(
    `
    UPDATE usuario
    SET activo = 0, actualizado_en = NOW()
    WHERE id = :id
    `,
    { id }
  );
};

export const eliminarUsuarioPermanente = async (id: number) => {
  await withTransaction(async (conn) => {
    await conn.execute(
      `
      DELETE FROM usuario_rol
      WHERE usuario_id = :id
      `,
      { id }
    );
    await conn.execute(
      `
      DELETE FROM usuario
      WHERE id = :id
      `,
      { id }
    );
  });
};

export const obtenerRolesDisponibles = async () => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT id, nombre, descripcion
    FROM rol
    ORDER BY nombre
    `
  );

  return rows.map((row) => ({
    id: row.id as number,
    nombre: row.nombre as string,
    descripcion: row.descripcion as string | null
  }));
};

