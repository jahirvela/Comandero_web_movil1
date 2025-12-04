import { pool } from '../src/db/pool.js';
import { logger } from '../src/config/logger.js';

/**
 * Script para eliminar todos los productos de la base de datos
 * Esto elimina:
 * - Todos los productos de la tabla `producto`
 * - Todos los tamaños relacionados en `producto_tamano`
 * - Todos los ingredientes relacionados en `producto_ingrediente`
 * 
 * ADVERTENCIA: Esta operación es irreversible
 */

async function verificarTablaExiste(connection: any, nombreTabla: string): Promise<boolean> {
  try {
    const [rows] = await connection.execute(
      `SELECT COUNT(*) as count FROM information_schema.tables 
       WHERE table_schema = DATABASE() AND table_name = ?`,
      [nombreTabla]
    );
    return (rows as any[])[0].count > 0;
  } catch {
    return false;
  }
}

async function limpiarProductos() {
  let connection;
  
  try {
    logger.info('Iniciando limpieza de productos...');
    
    connection = await pool.getConnection();
    await connection.beginTransaction();
    
    let totalProductosEliminados = 0;
    
    // 1. Eliminar ingredientes de productos (si la tabla existe)
    const existeIngredientes = await verificarTablaExiste(connection, 'producto_ingrediente');
    if (existeIngredientes) {
      logger.info('Eliminando ingredientes de productos...');
      const [ingredientesResult] = await connection.execute(
        'DELETE FROM producto_ingrediente'
      );
      logger.info(`Ingredientes eliminados: ${(ingredientesResult as any).affectedRows}`);
    } else {
      logger.info('Tabla producto_ingrediente no existe, omitiendo...');
    }
    
    // 2. Eliminar tamaños de productos (si la tabla existe)
    const existeTamanos = await verificarTablaExiste(connection, 'producto_tamano');
    if (existeTamanos) {
      logger.info('Eliminando tamaños de productos...');
      const [tamanosResult] = await connection.execute(
        'DELETE FROM producto_tamano'
      );
      logger.info(`Tamaños eliminados: ${(tamanosResult as any).affectedRows}`);
    } else {
      logger.info('Tabla producto_tamano no existe, omitiendo...');
    }
    
    // 3. Eliminar productos
    logger.info('Eliminando productos...');
    const [productosResult] = await connection.execute(
      'DELETE FROM producto'
    );
    totalProductosEliminados = (productosResult as any).affectedRows;
    logger.info(`Productos eliminados: ${totalProductosEliminados}`);
    
    await connection.commit();
    
    logger.info('✓ Limpieza de productos completada exitosamente');
    logger.info(`Total eliminado: ${totalProductosEliminados} productos`);
    
  } catch (error: any) {
    if (connection) {
      await connection.rollback();
    }
    logger.error({ err: error }, 'Error al limpiar productos');
    throw error;
  } finally {
    if (connection) {
      connection.release();
    }
    await pool.end();
  }
}

// Ejecutar el script
limpiarProductos()
  .then(() => {
    logger.info('Script completado');
    process.exit(0);
  })
  .catch((error) => {
    logger.error({ err: error }, 'Error fatal en el script');
    process.exit(1);
  });

