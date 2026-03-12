/**
 * Aplica las migraciones incrementales (aplicar-migraciones-local.sql) en la BD local.
 * Usa las credenciales de .env. Ejecutar desde la raíz del backend:
 *   npx tsx scripts/aplicar-migraciones-local.ts
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';
import * as fs from 'fs';
import * as path from 'path';

config();

const SCRIPT_NAME = 'aplicar-migraciones-local.sql';

async function main() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();
    const sqlPath = path.join(process.cwd(), 'scripts', SCRIPT_NAME);

    if (!fs.existsSync(sqlPath)) {
      throw new Error(`No se encontró el archivo: ${sqlPath}`);
    }

    console.log('========================================');
    console.log('APLICAR MIGRACIONES LOCALES (BD comandero)');
    console.log('========================================\n');
    console.log(`Archivo: ${SCRIPT_NAME}`);
    console.log(`Base de datos: ${env.DATABASE_NAME} @ ${env.DATABASE_HOST}:${env.DATABASE_PORT}\n`);

    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
      multipleStatements: true,
    });

    const sql = fs.readFileSync(sqlPath, 'utf-8');
    await connection.query(sql);

    console.log('✅ Migraciones aplicadas correctamente.');
    console.log('   Reinicia el backend si estaba corriendo.\n');
  } catch (err: any) {
    console.error('❌ Error al aplicar migraciones:', err.message);
    if (err.sqlMessage) console.error('   SQL:', err.sqlMessage);
    if (err.code === 'ER_NO_SUCH_TABLE') {
      console.error('\n   La base o tablas base no existen. Ejecuta primero:');
      console.error('   mysql -u root -p comandero < backups/comandero.sql');
    }
    process.exit(1);
  } finally {
    if (connection) await connection.end();
  }
}

main();
