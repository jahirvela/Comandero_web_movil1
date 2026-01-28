import { pool } from '../src/db/pool.js';
import { logger } from '../src/config/logger.js';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigration() {
  logger.info('Iniciando migración: Agregar columna tiempo_estimado_preparacion a tabla orden');
  
  try {
    // Verificar si la columna ya existe
    const [rows] = await pool.query<any[]>(
      `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
       WHERE TABLE_SCHEMA = DATABASE() 
       AND TABLE_NAME = 'orden' 
       AND COLUMN_NAME = 'tiempo_estimado_preparacion'`
    );

    if (rows.length > 0) {
      logger.warn('La columna "tiempo_estimado_preparacion" ya existe en la tabla "orden". Saltando migración.');
      return;
    }

    // Agregar la columna
    await pool.query(`
      ALTER TABLE orden 
      ADD COLUMN tiempo_estimado_preparacion INT UNSIGNED NULL 
      AFTER estado_orden_id
    `);
    
    logger.info('✅ Migración completada exitosamente: Columna "tiempo_estimado_preparacion" agregada a la tabla "orden"');

    // Verificar que la columna se haya creado
    const [checkRows] = await pool.query<any[]>(
      `SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT 
       FROM INFORMATION_SCHEMA.COLUMNS 
       WHERE TABLE_SCHEMA = DATABASE() 
       AND TABLE_NAME = 'orden' 
       AND COLUMN_NAME = 'tiempo_estimado_preparacion'`
    );
    
    if (checkRows.length > 0) {
      logger.info('Verificación: Columna "tiempo_estimado_preparacion" creada correctamente', checkRows[0]);
    } else {
      logger.error('Error de verificación: La columna "tiempo_estimado_preparacion" no se encontró después de la migración.');
    }

  } catch (error: any) {
    // Si el error es que la columna ya existe, solo loguear
    if (error.code === 'ER_DUP_FIELDNAME') {
      logger.warn('La columna "tiempo_estimado_preparacion" ya existe. Saltando migración.');
      return;
    }
    logger.error({ err: error }, '❌ Error durante la migración para agregar columna tiempo_estimado_preparacion');
    throw error;
  } finally {
    await pool.end();
    logger.info('Script de migración finalizado');
  }
}

runMigration().catch(err => {
  logger.error({ err }, 'Error fatal al ejecutar script de migración');
  process.exit(1);
});

