/**
 * Asegura la columna inventario_item.categoria en BD REMOTA (.env.remote) y BD LOCAL.
 * Local: usa backend/.env.local si existe (DATABASE_*); si no, 127.0.0.1:3306 root / comandero (contraseña vacía).
 * Ejecutar desde la carpeta backend: npm run migrate:inventory-category:both
 */

import mysql from 'mysql2/promise';
import * as fs from 'fs';
import * as path from 'path';

function loadEnvFile(filePath: string): Record<string, string> {
  if (!fs.existsSync(filePath)) return {};
  const content = fs.readFileSync(filePath, 'utf8');
  const out: Record<string, string> = {};
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    let val = trimmed.slice(eq + 1).trim();
    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }
    out[key] = val;
  }
  return out;
}

type DbTarget = { host: string; port: number; user: string; password: string; database: string };

async function ensureCategoriaColumn(
  conn: mysql.Connection,
  label: string
): Promise<void> {
  const [rows] = await conn.query<mysql.RowDataPacket[]>(
    `
    SELECT COLUMN_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'inventario_item'
      AND COLUMN_NAME = 'categoria'
    `
  );
  if (rows.length > 0) {
    console.log(`[${label}] ✓ La columna categoria ya existe`);
    return;
  }
  console.log(`[${label}] Agregando columna categoria...`);
  await conn.execute(
    `
    ALTER TABLE inventario_item
    ADD COLUMN categoria VARCHAR(64) NOT NULL DEFAULT 'Otros'
    `
  );
  console.log(`[${label}] ✓ Columna categoria agregada`);
}

async function runForDb(cfg: DbTarget, label: string): Promise<void> {
  let conn: mysql.Connection | null = null;
  try {
    conn = await mysql.createConnection({
      host: cfg.host,
      port: cfg.port,
      user: cfg.user,
      password: cfg.password,
      database: cfg.database,
      connectTimeout: 20000
    });
    await ensureCategoriaColumn(conn, label);
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`[${label}] ✗ ${msg}`);
  } finally {
    if (conn) await conn.end();
  }
}

async function main(): Promise<void> {
  const cwd = process.cwd();
  const remoteEnv = loadEnvFile(path.join(cwd, '.env.remote'));
  const localEnv = loadEnvFile(path.join(cwd, '.env.local'));

  const remote: DbTarget | null =
    remoteEnv.DATABASE_HOST &&
    remoteEnv.DATABASE_USER &&
    remoteEnv.DATABASE_PASSWORD != null &&
    remoteEnv.DATABASE_NAME
      ? {
          host: remoteEnv.DATABASE_HOST,
          port: Number(remoteEnv.DATABASE_PORT) || 3306,
          user: remoteEnv.DATABASE_USER,
          password: remoteEnv.DATABASE_PASSWORD,
          database: remoteEnv.DATABASE_NAME
        }
      : null;

  const local: DbTarget = {
    host: localEnv.DATABASE_HOST || '127.0.0.1',
    port: Number(localEnv.DATABASE_PORT) || 3306,
    user: localEnv.DATABASE_USER || 'root',
    password: localEnv.DATABASE_PASSWORD ?? '',
    database: localEnv.DATABASE_NAME || 'comandero'
  };

  console.log('=== migrate-inventory-category (remota + local) ===\n');

  if (remote) {
    console.log(
      `Remota: ${remote.database} @ ${remote.host}:${remote.port} (${remote.user})\n`
    );
    await runForDb(remote, 'REMOTA');
    console.log('');
  } else {
    console.log(
      '[REMOTA] Omitida: falta .env.remote o variables DATABASE_*.\n'
    );
  }

  if (localEnv.DATABASE_HOST) {
    console.log(
      `Local (.env.local): ${local.database} @ ${local.host}:${local.port} (${local.user})\n`
    );
  } else {
    console.log(
      `Local (por defecto): ${local.database} @ ${local.host}:${local.port} (${local.user}) — crea .env.local para otros datos.\n`
    );
  }
  await runForDb(local, 'LOCAL');
}

main()
  .then(() => {
    console.log('\nProceso terminado.');
    process.exit(0);
  })
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
