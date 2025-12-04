/**
 * Verificar índices y constraints de orden_item
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function verificarIndices() {
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

    console.log('Verificando índices y constraints...');
    console.log('');

    // Verificar si existe la tabla orden_item
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'orden_item'",
      [env.DATABASE_NAME]
    );

    if ((tables as any[]).length > 0) {
      console.log('⚠️  La tabla orden_item todavía existe');
      
      // Verificar índices
      const [indexes] = await connection.query(
        `SHOW INDEX FROM orden_item`
      );
      
      console.log('Índices en orden_item:');
      (indexes as any[]).forEach((idx: any) => {
        console.log(`   - ${idx.Key_name} (${idx.Column_name})`);
      });
    } else {
      console.log('✅ La tabla orden_item no existe');
    }

    // Verificar todos los índices con nombres similares
    const [allIndexes] = await connection.query(
      `SELECT 
        TABLE_NAME,
        INDEX_NAME,
        COLUMN_NAME
       FROM INFORMATION_SCHEMA.STATISTICS
       WHERE TABLE_SCHEMA = ?
         AND INDEX_NAME LIKE '%orden%' OR INDEX_NAME LIKE '%item%'
       ORDER BY TABLE_NAME, INDEX_NAME`,
      [env.DATABASE_NAME]
    );

    const indexList = allIndexes as any[];
    if (indexList.length > 0) {
      console.log('');
      console.log('Índices relacionados con orden/item:');
      indexList.forEach((idx: any) => {
        console.log(`   - ${idx.TABLE_NAME}.${idx.INDEX_NAME} (${idx.COLUMN_NAME})`);
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

verificarIndices();

