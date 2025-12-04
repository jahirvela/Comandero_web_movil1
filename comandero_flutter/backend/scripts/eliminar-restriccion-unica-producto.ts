import { pool } from '../src/db/pool.js';
import { logger } from '../src/config/logger.js';

/**
 * Script para eliminar la restricción única ux_producto_categoria_nombre
 * Esta restricción impide crear productos con el mismo nombre en la misma categoría
 * 
 * ADVERTENCIA: Esta operación es irreversible
 */

async function eliminarRestriccionUnica() {
  let connection;
  
  try {
    logger.info('Verificando restricción única ux_producto_categoria_nombre...');
    
    connection = await pool.getConnection();
    
    // Verificar si existe la restricción
    const [constraints] = await connection.execute(
      `SELECT 
        CONSTRAINT_NAME,
        TABLE_NAME,
        COLUMN_NAME
      FROM 
        INFORMATION_SCHEMA.KEY_COLUMN_USAGE
      WHERE 
        TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'producto'
        AND CONSTRAINT_NAME = 'ux_producto_categoria_nombre'`
    );
    
    const constraintsList = constraints as Array<{ CONSTRAINT_NAME: string; TABLE_NAME: string; COLUMN_NAME: string }>;
    
    if (constraintsList.length === 0) {
      logger.info('La restricción ux_producto_categoria_nombre no existe. No hay nada que eliminar.');
      return;
    }
    
    logger.info(`Restricción encontrada: ${constraintsList[0].CONSTRAINT_NAME}`);
    logger.info('Eliminando restricción única...');
    
    // Eliminar la restricción única (MySQL no soporta IF EXISTS en DROP INDEX)
    try {
      await connection.execute(
        'ALTER TABLE producto DROP INDEX ux_producto_categoria_nombre'
      );
    } catch (dropError: any) {
      if (dropError.code === 'ER_CANT_DROP_FIELD_OR_KEY') {
        logger.warn('La restricción ya no existe o tiene un nombre diferente');
      } else {
        throw dropError;
      }
    }
    
    logger.info('✓ Restricción única eliminada exitosamente');
    
    // Verificar que se eliminó
    const [verificacion] = await connection.execute(
      `SELECT 
        CONSTRAINT_NAME
      FROM 
        INFORMATION_SCHEMA.KEY_COLUMN_USAGE
      WHERE 
        TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'producto'
        AND CONSTRAINT_NAME = 'ux_producto_categoria_nombre'`
    );
    
    const verificacionList = verificacion as Array<{ CONSTRAINT_NAME: string }>;
    
    if (verificacionList.length === 0) {
      logger.info('✓ Confirmado: La restricción ha sido eliminada correctamente');
    } else {
      logger.warn('⚠ La restricción aún existe después del intento de eliminación');
    }
    
  } catch (error: any) {
    logger.error({ err: error }, 'Error al eliminar restricción única');
    throw error;
  } finally {
    if (connection) {
      connection.release();
    }
    await pool.end();
  }
}

// Ejecutar el script
eliminarRestriccionUnica()
  .then(() => {
    logger.info('Script completado');
    process.exit(0);
  })
  .catch((error) => {
    logger.error({ err: error }, 'Error fatal en el script');
    process.exit(1);
  });

