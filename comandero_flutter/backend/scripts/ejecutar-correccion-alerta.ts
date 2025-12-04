/**
 * Script para ejecutar la corrección de la tabla alerta
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';
import * as fs from 'fs';
import * as path from 'path';

config();

async function ejecutarCorreccion() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();

    console.log('========================================');
    console.log('CORRECCIÓN DE TABLA ALERTA');
    console.log('========================================');
    console.log('');

    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
      multipleStatements: true
    });

    console.log('✅ Conectado a la base de datos');
    console.log('');

    const sqlPath = path.join(process.cwd(), 'scripts', 'corregir-tabla-alerta.sql');
    
    if (!fs.existsSync(sqlPath)) {
      throw new Error(`No se encontró el archivo: ${sqlPath}`);
    }

    const sqlContent = fs.readFileSync(sqlPath, 'utf-8');
    
    console.log('📄 Ejecutando corrección de tabla alerta...');
    console.log('');

    await connection.query(sqlContent);

    console.log('✅ Corrección ejecutada exitosamente');
    console.log('');

  } catch (error: any) {
    console.error('❌ Error:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
    throw error;
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

ejecutarCorreccion()
  .then(() => {
    console.log('✅ Script finalizado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error fatal:', error);
    process.exit(1);
  });

