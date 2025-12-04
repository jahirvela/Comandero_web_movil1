/**
 * Script para crear usuario administrador en la estructura actual de la base de datos
 * Usa la tabla "usuarios" (plural) con la estructura actual
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';
import { hashPassword } from '../src/utils/password.js';

config();

async function crearAdmin() {
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

    // Datos del usuario
    const username = 'admin';
    const password = 'Demo123';
    const nombre = 'Administrador';
    const correo = 'admin'; // Usar "admin" como correo para que funcione como username
    const telefono = '555-0001';

    // Verificar si el usuario ya existe (por correo)
    const [existing] = await connection.query(
      'SELECT id, nombre, correo FROM usuarios WHERE correo = ?',
      [correo]
    );

    if ((existing as any[]).length > 0) {
      const user = (existing as any[])[0];
      console.log(`⚠️  Ya existe un usuario con correo "${correo}"`);
      console.log(`   ID: ${user.id}`);
      console.log(`   Nombre: ${user.nombre}`);
      console.log(`   Correo actual: ${user.correo}`);
      console.log('');
      console.log('Actualizando usuario...');
      
      const passwordHash = await hashPassword(password);
      await connection.query(
        'UPDATE usuarios SET nombre = ?, correo = ?, contraseña_hash = ?, rol = ?, actualizado_en = NOW() WHERE id = ?',
        [nombre, correo, passwordHash, 'admin', user.id]
      );
      
      console.log('✅ Usuario actualizado');
      console.log('');
      console.log('Credenciales:');
      console.log(`   Username/Correo: ${correo}`);
      console.log(`   Contraseña: ${password}`);
    } else {
      // Hashear la contraseña
      console.log('Generando hash de contraseña...');
      const passwordHash = await hashPassword(password);
      console.log('✅ Hash generado');
      console.log('');

      // Insertar usuario
      console.log('Creando usuario administrador...');
      const [result] = await connection.query(
        `INSERT INTO usuarios (nombre, correo, contraseña_hash, rol, activo, creado_en, actualizado_en)
         VALUES (?, ?, ?, 'admin', 1, NOW(), NOW())`,
        [nombre, correo, passwordHash]
      );

      const userId = (result as any).insertId;
      console.log(`✅ Usuario creado exitosamente`);
      console.log(`   ID: ${userId}`);
      console.log(`   Nombre: ${nombre}`);
      console.log(`   Correo: ${correo}`);
      console.log(`   Rol: admin`);
      console.log('');
      console.log('Credenciales:');
      console.log(`   Username/Correo: ${correo}`);
      console.log(`   Contraseña: ${password}`);
    }

    console.log('');
    console.log('========================================');
    console.log('✅ Proceso completado');
    console.log('========================================');

  } catch (error: any) {
    console.error('');
    console.error('❌ Error:', error.message);
    if (error.code) {
      console.error(`   Código: ${error.code}`);
    }
    if (error.sqlMessage) {
      console.error(`   SQL: ${error.sqlMessage}`);
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

crearAdmin();

