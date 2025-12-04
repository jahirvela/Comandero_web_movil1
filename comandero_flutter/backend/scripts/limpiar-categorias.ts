import { pool } from '../src/db/pool.js';
import { logger } from '../src/config/logger.js';

/**
 * Script para eliminar todas las categorías de la base de datos
 * 
 * ADVERTENCIA: Esta operación es irreversible
 * Nota: "Todos" no es una categoría real en la base de datos, es solo un filtro en la UI
 */

async function limpiarCategorias() {
  let connection;
  
  try {
    logger.info('Iniciando limpieza de categorías...');
    
    connection = await pool.getConnection();
    await connection.beginTransaction();
    
    // Primero, verificar qué categorías existen
    const [categorias] = await connection.execute(
      'SELECT id, nombre FROM categoria ORDER BY nombre'
    );
    
    const categoriasList = categorias as Array<{ id: number; nombre: string }>;
    logger.info(`Categorías encontradas: ${categoriasList.length}`);
    
    if (categoriasList.length > 0) {
      logger.info('Categorías a eliminar:');
      categoriasList.forEach(cat => {
        logger.info(`  - ${cat.nombre} (ID: ${cat.id})`);
      });
    }
    
    // Eliminar todas las categorías (DELETE real, no solo marcar como inactivo)
    logger.info('Eliminando categorías...');
    const [result] = await connection.execute(
      'DELETE FROM categoria'
    );
    
    const totalEliminadas = (result as any).affectedRows;
    logger.info(`Categorías eliminadas: ${totalEliminadas}`);
    
    await connection.commit();
    
    logger.info('✓ Limpieza de categorías completada exitosamente');
    logger.info(`Total eliminado: ${totalEliminadas} categorías`);
    
  } catch (error: any) {
    if (connection) {
      await connection.rollback();
    }
    logger.error({ err: error }, 'Error al limpiar categorías');
    throw error;
  } finally {
    if (connection) {
      connection.release();
    }
    await pool.end();
  }
}

// Ejecutar el script
limpiarCategorias()
  .then(() => {
    logger.info('Script completado');
    process.exit(0);
  })
  .catch((error) => {
    logger.error({ err: error }, 'Error fatal en el script');
    process.exit(1);
  });

