/**
 * Script para crear usuario administrador con username "admin"
 * Usa la estructura que el backend espera: tabla "usuario" con "username"
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

async function crearUsuarioAdmin() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();

    console.log('========================================');
    console.log('Crear Usuario Administrador');
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

    // Verificar si existe la tabla "usuario" (singular)
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'usuario'",
      [env.DATABASE_NAME]
    );

    if ((tables as any[]).length === 0) {
      console.log('⚠️  La tabla "usuario" no existe. Verificando estructura...');
      
      // Verificar columnas de la tabla usuarios si existe
      const [usuariosTables] = await connection.query(
        "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'usuarios'",
        [env.DATABASE_NAME]
      );
      
      if ((usuariosTables as any[]).length > 0) {
        console.log('⚠️  Existe la tabla "usuarios" (plural) pero el código espera "usuario" (singular)');
        console.log('   El backend espera la tabla "usuario" con columna "username"');
      }
      
      console.log('');
      console.log('Intentando crear usuario en la tabla "usuario"...');
    }

    // Verificar roles disponibles
    console.log('Verificando roles disponibles...');
    let rolAdminId: number | null = null;
    
    try {
      const [roles] = await connection.query(
        'SELECT id, nombre FROM rol ORDER BY nombre'
      );
      const rolesList = roles as Array<{ id: number; nombre: string }>;
      
      console.log('Roles encontrados:');
      rolesList.forEach((rol) => {
        console.log(`  - ID: ${rol.id}, Nombre: ${rol.nombre}`);
      });
      
      const rolAdmin = rolesList.find(
        (r) => r.nombre.toLowerCase() === 'administrador' || r.nombre.toLowerCase() === 'admin'
      );
      
      if (rolAdmin) {
        rolAdminId = rolAdmin.id;
        console.log(`✅ Rol administrador encontrado: ID ${rolAdmin.id}`);
      } else {
        console.log('⚠️  No se encontró rol de administrador, se creará sin rol');
      }
    } catch (error: any) {
      console.log('⚠️  No se pudo consultar roles (tabla "rol" puede no existir)');
      console.log('   Se creará el usuario sin asignar roles');
    }
    console.log('');

    // Datos del usuario
    const nombre = 'Administrador';
    const username = 'admin';
    const password = 'Demo123';
    const telefono = '555-0001';

    // Verificar si el usuario ya existe
    let usuarioExiste = false;
    let usuarioId: number | null = null;

    try {
      const [existing] = await connection.query(
        'SELECT id, nombre, username FROM usuario WHERE username = ?',
        [username]
      );
      const existingUsers = existing as Array<{ id: number; nombre: string; username: string }>;
      
      if (existingUsers.length > 0) {
        usuarioExiste = true;
        usuarioId = existingUsers[0].id;
        console.log(`⚠️  Ya existe un usuario con username "${username}"`);
        console.log(`   ID: ${usuarioId}`);
        console.log(`   Nombre: ${existingUsers[0].nombre}`);
        console.log('');
      }
    } catch (error: any) {
      console.log('⚠️  No se pudo verificar usuario existente, intentando crear...');
    }

    // Hashear la contraseña
    console.log('Generando hash de contraseña...');
    const passwordHash = await hashPassword(password);
    console.log('✅ Hash generado');
    console.log('');

    if (usuarioExiste && usuarioId) {
      console.log('Actualizando usuario existente...');
      await connection.query(
        `UPDATE usuario 
         SET nombre = ?, telefono = ?, password_hash = ?, activo = 1, 
             password_actualizada_en = NOW(), actualizado_en = NOW()
         WHERE id = ?`,
        [nombre, telefono, passwordHash, usuarioId]
      );

      // Asignar rol si existe
      if (rolAdminId) {
        // Eliminar roles existentes
        try {
          await connection.query(
            'DELETE FROM usuario_rol WHERE usuario_id = ?',
            [usuarioId]
          );
          await connection.query(
            'INSERT INTO usuario_rol (usuario_id, rol_id) VALUES (?, ?)',
            [usuarioId, rolAdminId]
          );
          console.log('✅ Rol de administrador asignado');
        } catch (error: any) {
          console.log('⚠️  No se pudo asignar rol (tabla usuario_rol puede no existir)');
        }
      }

      console.log('✅ Usuario actualizado');
    } else {
      console.log('Creando nuevo usuario...');
      const [result] = await connection.query(
        `INSERT INTO usuario (
          nombre, username, telefono, password_hash, activo,
          password_actualizada_en, creado_en, actualizado_en
        ) VALUES (?, ?, ?, ?, 1, NOW(), NOW(), NOW())`,
        [nombre, username, telefono, passwordHash]
      );
      usuarioId = (result as any).insertId;
      console.log('✅ Usuario creado exitosamente');
      console.log(`   ID: ${usuarioId}`);

      // Asignar rol si existe
      if (rolAdminId) {
        try {
          await connection.query(
            'INSERT INTO usuario_rol (usuario_id, rol_id) VALUES (?, ?)',
            [usuarioId, rolAdminId]
          );
          console.log('✅ Rol de administrador asignado');
        } catch (error: any) {
          console.log('⚠️  No se pudo asignar rol (tabla usuario_rol puede no existir)');
        }
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
    console.error('❌ Error durante la creación/actualización del usuario:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
    if (error.sqlMessage) {
      console.error('   SQL:', error.sqlMessage);
    }
    if (error.sql) {
      console.error('   Query:', error.sql);
    }
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

crearUsuarioAdmin();

