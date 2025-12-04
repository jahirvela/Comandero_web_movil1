/**
 * Script para verificar la estructura de la base de datos
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function verificarEstructura() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();

    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
    });

    console.log('========================================');
    console.log('Verificando estructura de la base de datos');
    console.log('========================================');
    console.log('');

    // Listar todas las tablas
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?",
      [env.DATABASE_NAME]
    );

    console.log('Tablas encontradas:');
    (tables as Array<{ TABLE_NAME: string }>).forEach((table) => {
      console.log(`  - ${table.TABLE_NAME}`);
    });
    console.log('');

    // Verificar si existe tabla usuario o usuarios
    const tableNames = (tables as Array<{ TABLE_NAME: string }>).map(t => t.TABLE_NAME.toLowerCase());
    
    if (tableNames.includes('usuario')) {
      console.log('✅ Tabla "usuario" encontrada');
      const [usuarioColumns] = await connection.query(
        "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'usuario'",
        [env.DATABASE_NAME]
      );
      console.log('Columnas de "usuario":');
      (usuarioColumns as Array<{ COLUMN_NAME: string; DATA_TYPE: string }>).forEach((col) => {
        console.log(`  - ${col.COLUMN_NAME} (${col.DATA_TYPE})`);
      });
      console.log('');
    }

    if (tableNames.includes('usuarios')) {
      console.log('✅ Tabla "usuarios" encontrada');
      const [usuariosColumns] = await connection.query(
        "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'usuarios'",
        [env.DATABASE_NAME]
      );
      console.log('Columnas de "usuarios":');
      (usuariosColumns as Array<{ COLUMN_NAME: string; DATA_TYPE: string }>).forEach((col) => {
        console.log(`  - ${col.COLUMN_NAME} (${col.DATA_TYPE})`);
      });
      console.log('');
    }

    // Verificar roles
    if (tableNames.includes('rol')) {
      console.log('✅ Tabla "rol" encontrada');
      const [roles] = await connection.query('SELECT * FROM rol');
      console.log('Roles en la base de datos:');
      (roles as any[]).forEach((rol: any) => {
        console.log(`  - ID: ${rol.id}, Nombre: ${rol.nombre}`);
      });
      console.log('');
    } else {
      console.log('⚠️  Tabla "rol" NO encontrada');
    }

    // Verificar usuario_rol
    if (tableNames.includes('usuario_rol')) {
      console.log('✅ Tabla "usuario_rol" encontrada');
    } else {
      console.log('⚠️  Tabla "usuario_rol" NO encontrada');
    }

  } catch (error: any) {
    console.error('❌ Error:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

verificarEstructura();

