/**
 * Script para ejecutar la migración que agrega la columna 'password' a la tabla 'usuario'
 * 
 * Ejecutar con: npx tsx scripts/run-add-password-column.ts
 * O con: npm run migrate:add-password-column (si está configurado en package.json)
 */

import { pool } from '../src/db/pool.js';
import { logger } from '../src/config/logger.js';

async function addPasswordColumn() {
  let connection;
  
  try {
    logger.info('Iniciando migración: Agregar columna password a tabla usuario');
    
    // Obtener conexión del pool
    connection = await pool.getConnection();
    
    // Verificar si la columna ya existe
    const [columns] = await connection.query<any[]>(
      `
      SELECT COLUMN_NAME 
      FROM information_schema.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'usuario'
        AND COLUMN_NAME = 'password'
      `
    );
    
    if (columns.length > 0) {
      logger.info('La columna "password" ya existe en la tabla "usuario". No es necesario agregarla.');
      return;
    }
    
    // Ejecutar el ALTER TABLE
    await connection.query(
      `
      ALTER TABLE usuario 
      ADD COLUMN password VARCHAR(255) NULL 
      AFTER password_hash
      `
    );
    
    logger.info('✅ Migración completada exitosamente: Columna "password" agregada a la tabla "usuario"');
    
    // Verificar que se agregó correctamente
    const [verifyColumns] = await connection.query<any[]>(
      `
      SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT
      FROM information_schema.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'usuario'
        AND COLUMN_NAME = 'password'
      `
    );
    
    if (verifyColumns.length > 0) {
      const col = verifyColumns[0];
      logger.info({
        columnName: col.COLUMN_NAME,
        dataType: col.DATA_TYPE,
        isNullable: col.IS_NULLABLE,
        defaultValue: col.COLUMN_DEFAULT,
      }, 'Verificación: Columna "password" creada correctamente');
    }
    
  } catch (error: any) {
    logger.error({ err: error }, '❌ Error al ejecutar la migración');
    
    // Si el error es que la columna ya existe, no es un error crítico
    if (error.code === 'ER_DUP_FIELDNAME') {
      logger.info('La columna "password" ya existe. No es necesario agregarla.');
      return;
    }
    
    throw error;
  } finally {
    if (connection) {
      connection.release();
    }
    // Cerrar el pool después de un breve delay para asegurar que todas las conexiones se cierren
    setTimeout(() => {
      pool.end();
      process.exit(0);
    }, 1000);
  }
}

// Ejecutar la migración
addPasswordColumn()
  .then(() => {
    logger.info('Script de migración finalizado');
  })
  .catch((error) => {
    logger.error({ err: error }, 'Error fatal en el script de migración');
    process.exit(1);
  });

