/**
 * Verifica conexión a la base de datos remota (usa .env.remote).
 * Uso: desde backend/ ejecutar: npx dotenv -e .env.remote -- tsx scripts/verificar-conexion-remota.ts
 * O cargar .env.remote manualmente y ejecutar: tsx scripts/verificar-conexion-remota.ts
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import * as path from 'path';

// Cargar .env.remote si existe (solo variables de BD para esta prueba)
config({ path: path.join(process.cwd(), '.env.remote') });

const host = process.env.DATABASE_HOST || process.env.DB_HOST;
const port = Number(process.env.DATABASE_PORT || process.env.DB_PORT) || 3306;
const user = process.env.DATABASE_USER || process.env.DB_USER;
const password = process.env.DATABASE_PASSWORD || process.env.DB_PASSWORD;
const database = process.env.DATABASE_NAME || process.env.DB_NAME;

async function main() {
  if (!host || !user || !password || !database) {
    console.error('Faltan variables. Crea backend/.env.remote con:');
    console.error('DATABASE_HOST=... DATABASE_PORT=3306 DATABASE_USER=... DATABASE_PASSWORD=... DATABASE_NAME=comandix');
    process.exit(1);
  }
  let conn: mysql.Connection | null = null;
  try {
    conn = await mysql.createConnection({
      host,
      port,
      user,
      password,
      database,
    });
    console.log('Conexión remota OK:', host + ':' + port, 'DB:', database, '\n');

    const [tables] = await conn.query<mysql.RowDataPacket[]>(
      "SELECT TABLE_NAME, TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME",
      [database]
    );
    console.log('Tablas en la base de datos remota:', tables.length);
    console.log('----------------------------------------');
    for (const row of tables) {
      console.log('  ', row.TABLE_NAME, row.TABLE_ROWS != null ? `(~${row.TABLE_ROWS} filas)` : '');
    }
  } catch (e: any) {
    console.error('Error al conectar:', e.message);
    process.exit(1);
  } finally {
    if (conn) await conn.end();
  }
}

main();
