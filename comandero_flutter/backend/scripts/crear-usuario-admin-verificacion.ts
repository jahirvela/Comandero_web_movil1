/**
 * Script para crear un usuario administrador para verificar funcionalidades
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

    // Verificar roles disponibles
    console.log('Verificando roles disponibles...');
    const [roles] = await connection.query(
      'SELECT id, nombre FROM rol ORDER BY nombre'
    );
    const rolesList = roles as Array<{ id: number; nombre: string }>;
    
    console.log('Roles encontrados:');
    rolesList.forEach((rol) => {
      console.log(`  - ID: ${rol.id}, Nombre: ${rol.nombre}`);
    });
    console.log('');

    // Buscar el rol de administrador (puede ser "Administrador", "administrador", etc.)
    const rolAdmin = rolesList.find(
      (r) => r.nombre.toLowerCase() === 'administrador' || r.nombre.toLowerCase() === 'admin'
    );

    if (!rolAdmin) {
      console.error('❌ No se encontró el rol de administrador');
      console.log('Roles disponibles:', rolesList.map((r) => r.nombre).join(', '));
      return;
    }

    console.log(`✅ Rol administrador encontrado: ID ${rolAdmin.id} (${rolAdmin.nombre})`);
    console.log('');

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
      console.log('Actualizando usuario y asignando rol de administrador...');

      // Hashear la contraseña
      const passwordHash = await hashPassword(password);
      
      // Actualizar usuario
      await connection.query(
        `UPDATE usuario 
         SET nombre = ?, telefono = ?, password_hash = ?, activo = 1, 
             password_actualizada_en = NOW(), actualizado_en = NOW()
         WHERE id = ?`,
        [nombre, telefono, passwordHash, user.id]
      );

      // Eliminar roles existentes y asignar rol de administrador
      await connection.query(
        'DELETE FROM usuario_rol WHERE usuario_id = ?',
        [user.id]
      );
      await connection.query(
        'INSERT INTO usuario_rol (usuario_id, rol_id) VALUES (?, ?)',
        [user.id, rolAdmin.id]
      );

      console.log('✅ Usuario actualizado');
      console.log('');
      console.log('Credenciales:');
      console.log(`   Username: ${username}`);
      console.log(`   Contraseña: ${password}`);
      console.log(`   Rol: ${rolAdmin.nombre}`);
    } else {
      // Hashear la contraseña
      console.log('Generando hash de contraseña...');
      const passwordHash = await hashPassword(password);
      console.log('✅ Hash generado');

      // Insertar usuario
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
      console.log(`   Nombre: ${nombre}`);
      console.log(`   Username: ${username}`);

      // Asignar rol de administrador
      console.log('Asignando rol de administrador...');
      await connection.query(
        'INSERT INTO usuario_rol (usuario_id, rol_id) VALUES (?, ?)',
        [userId, rolAdmin.id]
      );
      console.log('✅ Rol asignado');

      console.log('');
      console.log('Credenciales:');
      console.log(`   Username: ${username}`);
      console.log(`   Contraseña: ${password}`);
      console.log(`   Rol: ${rolAdmin.nombre}`);
    }

    console.log('');
    console.log('========================================');
    console.log('✅ Proceso completado');
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
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

crearUsuarioAdmin();

