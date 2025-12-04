/**
 * Script para crear la tabla "usuario" (si no existe) y crear usuario administrador
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import bcrypt from 'bcrypt';
import { getEnv } from '../src/config/env.js';

config();

async function hashPassword(password: string): Promise<string> {
  const saltRounds = 10;
  return bcrypt.hash(password, saltRounds);
}

async function crearTablaYUsuario() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();

    console.log('========================================');
    console.log('Crear Tabla Usuario y Usuario Administrador');
    console.log('========================================');
    console.log('');

    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
    });

    console.log('✅ Conectado a la base de datos');
    console.log('');

    // Verificar si existe la tabla "usuario"
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'usuario'",
      [env.DATABASE_NAME]
    );

    if ((tables as any[]).length === 0) {
      console.log('📝 Creando tabla "usuario"...');
      
      await connection.query(`
        CREATE TABLE IF NOT EXISTS usuario (
          id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
          nombre VARCHAR(255) NOT NULL,
          username VARCHAR(100) NOT NULL UNIQUE,
          telefono VARCHAR(40) NULL,
          password_hash VARCHAR(255) NOT NULL,
          activo TINYINT(1) NOT NULL DEFAULT 1,
          ultimo_acceso TIMESTAMP NULL,
          password_actualizada_en TIMESTAMP NULL,
          password_actualizada_por_usuario_id BIGINT UNSIGNED NULL,
          creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_username (username),
          INDEX idx_activo (activo)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
      
      console.log('✅ Tabla "usuario" creada');
      console.log('');
    } else {
      console.log('✅ Tabla "usuario" ya existe');
      console.log('');
    }

    // Verificar si existe la tabla "rol" y "usuario_rol"
    const [rolTables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME IN ('rol', 'usuario_rol')",
      [env.DATABASE_NAME]
    );

    const existingTables = (rolTables as Array<{ TABLE_NAME: string }>).map(t => t.TABLE_NAME);
    let rolAdminId: number | null = null;

    if (existingTables.includes('rol') && existingTables.includes('usuario_rol')) {
      console.log('✅ Tablas "rol" y "usuario_rol" existen');
      
      // Buscar rol administrador
      const [roles] = await connection.query(
        "SELECT id, nombre FROM rol WHERE nombre LIKE '%admin%' OR nombre LIKE '%Administrador%'"
      );
      const rolesList = roles as Array<{ id: number; nombre: string }>;
      
      if (rolesList.length > 0) {
        rolAdminId = rolesList[0].id;
        console.log(`✅ Rol administrador encontrado: ID ${rolAdminId} (${rolesList[0].nombre})`);
      } else {
        console.log('⚠️  No se encontró rol de administrador');
      }
      console.log('');
    } else {
      console.log('⚠️  Tablas "rol" y "usuario_rol" no existen, se creará usuario sin roles');
      console.log('');
    }

    // Datos del usuario
    const nombre = 'Administrador';
    const username = 'admin';
    const password = 'Demo123';
    const telefono = '555-0001';

    // Verificar si el usuario ya existe
    const [existing] = await connection.query(
      'SELECT id, nombre, username FROM usuario WHERE username = ?',
      [username]
    );
    const existingUsers = existing as Array<{ id: number; nombre: string; username: string }>;

    if (existingUsers.length > 0) {
      const user = existingUsers[0];
      console.log(`⚠️  Ya existe un usuario con username "${username}"`);
      console.log(`   ID: ${user.id}`);
      console.log(`   Nombre: ${user.nombre}`);
      console.log('');
      console.log('Actualizando usuario...');

      const passwordHash = await hashPassword(password);
      
      await connection.query(
        `UPDATE usuario 
         SET nombre = ?, telefono = ?, password_hash = ?, activo = 1, 
             password_actualizada_en = NOW(), actualizado_en = NOW()
         WHERE id = ?`,
        [nombre, telefono, passwordHash, user.id]
      );

      // Asignar rol si existe
      if (rolAdminId) {
        await connection.query(
          'DELETE FROM usuario_rol WHERE usuario_id = ?',
          [user.id]
        );
        await connection.query(
          'INSERT INTO usuario_rol (usuario_id, rol_id) VALUES (?, ?)',
          [user.id, rolAdminId]
        );
        console.log('✅ Rol de administrador asignado');
      }

      console.log('✅ Usuario actualizado');
    } else {
      console.log('Generando hash de contraseña...');
      const passwordHash = await hashPassword(password);
      console.log('✅ Hash generado');

      console.log('Creando usuario administrador...');
      const [result] = await connection.query(
        `INSERT INTO usuario (
          nombre, username, telefono, password_hash, activo,
          password_actualizada_en, creado_en, actualizado_en
        ) VALUES (?, ?, ?, ?, 1, NOW(), NOW(), NOW())`,
        [nombre, username, telefono, passwordHash]
      );
      const userId = (result as any).insertId;
      console.log('✅ Usuario creado exitosamente');
      console.log(`   ID: ${userId}`);

      // Asignar rol si existe
      if (rolAdminId) {
        await connection.query(
          'INSERT INTO usuario_rol (usuario_id, rol_id) VALUES (?, ?)',
          [userId, rolAdminId]
        );
        console.log('✅ Rol de administrador asignado');
      }
    }

    console.log('');
    console.log('========================================');
    console.log('✅ Proceso completado');
    console.log('');
    console.log('Credenciales para iniciar sesión:');
    console.log(`   Username: ${username}`);
    console.log(`   Contraseña: ${password}`);
    console.log('');
    console.log('Ahora puedes usar estas credenciales para:');
    console.log('  - Iniciar sesión en la aplicación');
    console.log('  - Verificar funcionalidades desde la interfaz');
    console.log('========================================');
  } catch (error: any) {
    console.error('❌ Error:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
    if (error.sqlMessage) {
      console.error('   SQL:', error.sqlMessage);
    }
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

crearTablaYUsuario();

