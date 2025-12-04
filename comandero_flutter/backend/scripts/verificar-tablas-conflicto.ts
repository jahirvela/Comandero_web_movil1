/**
 * Verificar tablas que puedan causar conflictos
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function verificarTablas() {
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

    console.log('Verificando tablas que puedan causar conflictos...');
    console.log('');

    // Buscar tablas que puedan tener foreign keys a orden_item
    const [fkInfo] = await connection.query(
      `SELECT 
        TABLE_NAME,
        CONSTRAINT_NAME,
        REFERENCED_TABLE_NAME,
        REFERENCED_COLUMN_NAME
       FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
       WHERE TABLE_SCHEMA = ?
         AND REFERENCED_TABLE_NAME = 'orden_item'`,
      [env.DATABASE_NAME]
    );

    const fkList = fkInfo as any[];
    if (fkList.length > 0) {
      console.log('⚠️  Tablas con foreign keys a orden_item:');
      fkList.forEach((fk: any) => {
        console.log(`   - ${fk.TABLE_NAME} (FK: ${fk.CONSTRAINT_NAME})`);
      });
    }

    // Verificar si existe tabla orden_item
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME LIKE '%orden%'",
      [env.DATABASE_NAME]
    );

    const tableList = tables as Array<{ TABLE_NAME: string }>;
    if (tableList.length > 0) {
      console.log('');
      console.log('Tablas relacionadas con orden:');
      tableList.forEach((t) => {
        console.log(`   - ${t.TABLE_NAME}`);
      });
    }

  } catch (error: any) {
    console.error('Error:', error.message);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

verificarTablas();

