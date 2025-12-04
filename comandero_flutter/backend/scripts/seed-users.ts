/**
 * Script para crear los usuarios iniciales con contraseñas hasheadas
 *
 * Ejecutar: npx tsx scripts/seed-users.ts
 */

import { config } from 'dotenv';
import { pool } from '../src/db/pool.js';
import { hashPassword } from '../src/utils/password.js';
import { logger } from '../src/config/logger.js';

config();

const USERS = [
  {
    nombre: 'Administrador General',
    username: 'admin',
    telefono: null,
    password: 'Demo1234',
    roles: [1] // administrador
  },
  {
    nombre: 'Cajero Demo',
    username: 'cajero1',
    telefono: '555-1001',
    password: 'Demo1234',
    roles: [2] // cajero
  },
  {
    nombre: 'Capitán Demo',
    username: 'capitan1',
    telefono: '555-1002',
    password: 'Demo1234',
    roles: [3] // capitan
  },
  {
    nombre: 'Mesero Demo',
    username: 'mesero1',
    telefono: '555-1003',
    password: 'Demo1234',
    roles: [4] // mesero
  },
  {
    nombre: 'Cocinero Demo',
    username: 'cocinero1',
    telefono: '555-1004',
    password: 'Demo1234',
    roles: [5] // cocinero
  },
  {
    nombre: 'Admin-Caja Demo',
    username: 'admincaja',
    telefono: '555-1010',
    password: 'Demo1234',
    roles: [1, 2] // administrador + cajero
  }
];

async function seedUsers() {
  try {
    logger.info('Iniciando creación de usuarios...');

    // Verificar que los roles existan
    const [roles] = await pool.query<any[]>(
      'SELECT id, nombre FROM rol ORDER BY id'
    );

    if (roles.length === 0) {
      logger.error('No se encontraron roles en la base de datos. Ejecuta primero el script SQL para crear los roles.');
      await pool.end();
      process.exit(1);
    }

    logger.info({ roles: roles.map((r) => r.nombre) }, 'Roles encontrados');

    for (const userData of USERS) {
      // Verificar si el usuario ya existe
      const [existing] = await pool.query<any[]>(
        'SELECT id FROM usuario WHERE username = ?',
        [userData.username]
      );

      if (existing.length > 0) {
        logger.info({ username: userData.username }, 'Usuario ya existe, saltando...');
        continue;
      }

      // Hashear la contraseña
      const passwordHash = await hashPassword(userData.password);

      // Insertar usuario
      const [result] = await pool.query<any>(
        `INSERT INTO usuario (nombre, username, telefono, password_hash, activo, password_actualizada_en)
         VALUES (?, ?, ?, ?, 1, NOW())`,
        [userData.nombre, userData.username, userData.telefono, passwordHash]
      );

      const userId = (result as any).insertId;
      logger.info({ username: userData.username, userId }, 'Usuario creado');

      // Asignar roles
      for (const rolId of userData.roles) {
        await pool.query(
          'INSERT IGNORE INTO usuario_rol (usuario_id, rol_id) VALUES (?, ?)',
          [userId, rolId]
        );
      }

      logger.info({ username: userData.username, roles: userData.roles }, 'Roles asignados');
    }

    logger.info('✓ Usuarios creados correctamente');
    logger.info('');
    logger.info('Credenciales de acceso:');
    logger.info('  Usuario: admin');
    logger.info('  Contraseña: Demo1234');
    logger.info('');
    logger.info('Otros usuarios disponibles: cajero1, capitan1, mesero1, cocinero1, admincaja');
    logger.info('Todos con contraseña: Demo1234');

    await pool.end();
    process.exit(0);
  } catch (error) {
    logger.error({ err: error }, 'Error al crear usuarios');
    await pool.end();
    process.exit(1);
  }
}

seedUsers();

