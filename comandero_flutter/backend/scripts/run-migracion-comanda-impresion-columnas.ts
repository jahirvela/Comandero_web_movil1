/**
 * Añade a comanda_impresion las columnas impreso_automaticamente y es_reimpresion
 * si no existen (esquema antiguo). Si la tabla no existe, la crea con el esquema completo.
 * Ejecutar desde la raíz del backend: npx tsx scripts/run-migracion-comanda-impresion-columnas.ts
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

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
    });

    const db = env.DATABASE_NAME;

    const [tableCheck] = await connection.query<mysql.RowDataPacket[]>(
      `SELECT COUNT(*) AS c FROM information_schema.tables
       WHERE table_schema = ? AND table_name = 'comanda_impresion'`,
      [db]
    );

    if (Number(tableCheck[0]?.c) === 0) {
      console.log('Tabla comanda_impresion no existe. Creando con esquema completo...');
      await connection.query(`
        CREATE TABLE comanda_impresion (
          id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          orden_id BIGINT UNSIGNED NOT NULL,
          impreso_automaticamente BOOLEAN NOT NULL DEFAULT 1,
          impreso_por_usuario_id BIGINT UNSIGNED NULL,
          es_reimpresion BOOLEAN NOT NULL DEFAULT 0,
          creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (id),
          KEY ix_comanda_orden (orden_id),
          KEY ix_comanda_usuario (impreso_por_usuario_id),
          KEY ix_comanda_automatica (impreso_automaticamente),
          CONSTRAINT fk_comanda_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
          CONSTRAINT fk_comanda_usuario FOREIGN KEY (impreso_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE ON DELETE SET NULL
        ) ENGINE=InnoDB
      `);
      console.log('Tabla comanda_impresion creada correctamente.');
      return;
    }

    const [columns] = await connection.query<mysql.RowDataPacket[]>(
      `SELECT COLUMN_NAME FROM information_schema.columns
       WHERE table_schema = ? AND table_name = 'comanda_impresion'`,
      [db]
    );
    const columnNames = (columns || []).map((r) => r.COLUMN_NAME as string);

    let changed = false;

    if (!columnNames.includes('impreso_automaticamente')) {
      console.log('Añadiendo columna impreso_automaticamente...');
      await connection.query(`
        ALTER TABLE comanda_impresion
          ADD COLUMN impreso_automaticamente BOOLEAN NOT NULL DEFAULT 1 AFTER orden_id
      `);
      changed = true;
    }

    if (!columnNames.includes('impreso_por_usuario_id') && columnNames.includes('usuario_id')) {
      console.log('Añadiendo columna impreso_por_usuario_id (y copiando datos de usuario_id)...');
      await connection.query(`
        ALTER TABLE comanda_impresion
          ADD COLUMN impreso_por_usuario_id BIGINT UNSIGNED NULL AFTER impreso_automaticamente
      `);
      await connection.query(`
        UPDATE comanda_impresion SET impreso_por_usuario_id = usuario_id WHERE usuario_id IS NOT NULL
      `);
      changed = true;
    }

    if (!columnNames.includes('es_reimpresion')) {
      console.log('Añadiendo columna es_reimpresion...');
      await connection.query(`
        ALTER TABLE comanda_impresion
          ADD COLUMN es_reimpresion BOOLEAN NOT NULL DEFAULT 0 AFTER creado_en
      `);
      changed = true;
    }

    if (changed) {
      console.log('Migración comanda_impresion aplicada correctamente.');
    } else {
      console.log('comanda_impresion ya tiene el esquema actual. Nada que hacer.');
    }
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
