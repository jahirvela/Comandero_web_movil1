/**
 * Ejecuta la migración 20250213: producto_nombre y producto_tamano_etiqueta en orden_item,
 * producto_id nullable y FK ON DELETE SET NULL (para poder eliminar productos sin romper tickets/reportes).
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { getEnv } from '../src/config/env.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

config();

async function run() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();
    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
      multipleStatements: true,
    });

    const [cols] = await connection.query<mysql.RowDataPacket[]>(
      `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'orden_item' AND COLUMN_NAME = 'producto_nombre'`,
      [env.DATABASE_NAME]
    );

    if (cols.length > 0) {
      console.log('Migración ya aplicada (orden_item.producto_nombre existe). Nada que hacer.');
      return;
    }

    const sqlPath = path.join(__dirname, '..', 'docs', 'migraciones', '20250213_orden_item_producto_nombre.sql');
    if (!fs.existsSync(sqlPath)) {
      throw new Error('No se encontró el archivo de migración: ' + sqlPath);
    }

    const sql = fs.readFileSync(sqlPath, 'utf-8');
    console.log('Ejecutando migración: orden_item producto_nombre / producto_tamano_etiqueta y FK ON DELETE SET NULL...');
    await connection.query(sql);
    console.log('Migración aplicada correctamente.');
  } catch (err: any) {
    console.error('Error:', err.message);
    if (err.sqlMessage) console.error('SQL:', err.sqlMessage);
    throw err;
  } finally {
    if (connection) await connection.end();
  }
}

run()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
