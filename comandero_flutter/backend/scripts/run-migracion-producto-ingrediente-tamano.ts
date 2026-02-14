/**
 * Agrega la columna producto_tamano_id a producto_ingrediente para recetas por tamaño
 * (chico, mediano, grande). Si la columna ya existe, no hace nada.
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

    const [tableCheck] = await connection.query<mysql.RowDataPacket[]>(
      `SELECT COUNT(*) AS c FROM information_schema.tables
       WHERE table_schema = ? AND table_name = 'producto_ingrediente'`,
      [env.DATABASE_NAME]
    );
    if (Number(tableCheck[0]?.c) === 0) {
      console.log('La tabla producto_ingrediente no existe. Crea primero la tabla (ej. crear-tabla-producto-ingrediente).');
      return;
    }

    const [cols] = await connection.query<mysql.RowDataPacket[]>(
      `SELECT COLUMN_NAME FROM information_schema.columns
       WHERE table_schema = ? AND table_name = 'producto_ingrediente' AND column_name = 'producto_tamano_id'`,
      [env.DATABASE_NAME]
    );

    if (cols.length > 0) {
      console.log('Migración ya aplicada (producto_ingrediente.producto_tamano_id existe). Nada que hacer.');
      return;
    }

    console.log('Agregando columna producto_tamano_id a producto_ingrediente...');
    await connection.query(`
      ALTER TABLE producto_ingrediente
        ADD COLUMN producto_tamano_id BIGINT UNSIGNED NULL AFTER producto_id
    `);

    try {
      await connection.query(`
        ALTER TABLE producto_ingrediente
          ADD INDEX idx_producto_ingrediente_tamano (producto_tamano_id)
      `);
    } catch (e: any) {
      if (e.code !== 'ER_DUP_KEYNAME') throw e;
    }

    try {
      await connection.query(`
        ALTER TABLE producto_ingrediente
          ADD CONSTRAINT fk_producto_ingrediente_tamano
          FOREIGN KEY (producto_tamano_id) REFERENCES producto_tamano(id) ON DELETE SET NULL
      `);
    } catch (e: any) {
      if (e.code !== 'ER_DUP_KEYNAME' && e.code !== 'ER_FK_DUP_NAME') throw e;
    }

    console.log('Migración aplicada correctamente. Recetas por tamaño listas.');
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
