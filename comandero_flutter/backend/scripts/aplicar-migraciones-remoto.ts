/**
 * Aplica las migraciones incrementales en la BD REMOTA.
 * Usa las credenciales de .env.remote (NO usa getEnv para no requerir JWT etc).
 * Ejecutar desde la raíz del backend:
 *   npx tsx scripts/aplicar-migraciones-remoto.ts
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import * as fs from 'fs';
import * as path from 'path';

config({ path: path.join(process.cwd(), '.env.remote') });

const SCRIPT_NAME = 'aplicar-migraciones-local.sql';

async function main() {
  const host = process.env.DATABASE_HOST;
  const port = Number(process.env.DATABASE_PORT) || 3306;
  const user = process.env.DATABASE_USER;
  const password = process.env.DATABASE_PASSWORD;
  const database = process.env.DATABASE_NAME;

  if (!host || !user || !password || !database) {
    console.error('Faltan variables en .env.remote: DATABASE_HOST, DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME');
    process.exit(1);
  }

  let connection: mysql.Connection | null = null;

  try {
    const sqlPath = path.join(process.cwd(), 'scripts', SCRIPT_NAME);
    if (!fs.existsSync(sqlPath)) {
      throw new Error(`No se encontró el archivo: ${sqlPath}`);
    }

    console.log('========================================');
    console.log('APLICAR MIGRACIONES EN BD REMOTA');
    console.log('========================================\n');
    console.log(`Archivo: ${SCRIPT_NAME}`);
    console.log(`Base de datos: ${database} @ ${host}:${port}\n`);

    connection = await mysql.createConnection({
      host,
      port,
      user,
      password,
      database,
      multipleStatements: true,
    });

    let sql = fs.readFileSync(sqlPath, 'utf-8');
    // En remoto la BD puede ser "comandix"; reemplazar USE comandero por la BD actual
    sql = sql.replace(/USE\s+comandero\s*;/i, `USE \`${database}\`;`);
    await connection.query(sql);

    console.log('✅ Migraciones aplicadas correctamente en la BD remota.');
    console.log('   El backend en servidor ya puede usar la estructura actualizada.\n');
  } catch (err: any) {
    console.error('❌ Error al aplicar migraciones:', err.message);
    if (err.sqlMessage) console.error('   SQL:', err.sqlMessage);
    process.exit(1);
  } finally {
    if (connection) await connection.end();
  }
}

main();
