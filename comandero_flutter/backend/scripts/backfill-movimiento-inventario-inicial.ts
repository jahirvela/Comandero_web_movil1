/**
 * Inserta movimientos de entrada iniciales para ítems con stock y sin ninguna fila en movimiento_inventario.
 *
 * Uso (desde la carpeta backend):
 *   npx tsx scripts/backfill-movimiento-inventario-inicial.ts
 *   npx tsx scripts/backfill-movimiento-inventario-inicial.ts --env .env
 *   npx tsx scripts/backfill-movimiento-inventario-inicial.ts --env .env.qa
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import type { ResultSetHeader } from 'mysql2';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function resolveEnvPath(): string {
  const eq = process.argv.find((a) => a.startsWith('--env='));
  if (eq) return path.resolve(process.cwd(), eq.slice('--env='.length));
  const idx = process.argv.indexOf('--env');
  if (idx >= 0 && process.argv[idx + 1]) {
    return path.resolve(process.cwd(), process.argv[idx + 1]);
  }
  return path.join(process.cwd(), '.env');
}

async function main() {
  const envFile = resolveEnvPath();
  config({ path: envFile });

  const host = process.env.DATABASE_HOST;
  const port = Number(process.env.DATABASE_PORT) || 3306;
  const user = process.env.DATABASE_USER;
  const password = process.env.DATABASE_PASSWORD;
  const database = process.env.DATABASE_NAME;

  if (!host || !user || password === undefined || !database) {
    console.error(
      'Faltan variables: DATABASE_HOST, DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME',
    );
    console.error(`Archivo usado: ${envFile}`);
    process.exit(1);
  }

  const sqlPath = path.join(__dirname, 'backfill-movimiento-inventario-inicial.sql');
  if (!fs.existsSync(sqlPath)) {
    console.error(`No se encontró: ${sqlPath}`);
    process.exit(1);
  }

  const sql = fs.readFileSync(sqlPath, 'utf-8');

  console.log('========================================');
  console.log('Backfill movimiento_inventario (inicial)');
  console.log('========================================');
  console.log(`Env: ${envFile}`);
  console.log(`BD:  ${database} @ ${host}:${port}\n`);

  const connection = await mysql.createConnection({
    host,
    port,
    user,
    password,
    database,
    multipleStatements: false,
  });

  try {
    const [result] = await connection.query<ResultSetHeader>(sql);
    const affected = result.affectedRows ?? 0;
    console.log(`✅ Filas insertadas: ${affected}`);
    if (affected === 0) {
      console.log(
        '   (Nada que hacer: todos los ítems con stock ya tienen al menos un movimiento, o stock en cero.)',
      );
    }
  } finally {
    await connection.end();
  }
}

main().catch((e) => {
  console.error('❌ Error:', e.message);
  if (e.sqlMessage) console.error('   SQL:', e.sqlMessage);
  process.exit(1);
});
