import { pool } from '../src/db/pool.js';
import { logger } from '../src/config/logger.js';

/**
 * Script para crear la tabla producto_ingrediente si no existe
 * Esta tabla es necesaria para almacenar los ingredientes de las recetas de productos
 */

async function crearTablaProductoIngrediente() {
  let connection;
  
  try {
    logger.info('Verificando si existe la tabla producto_ingrediente...');
    
    connection = await pool.getConnection();
    
    // Verificar si existe la tabla
    const [tables] = await connection.execute(
      `SELECT COUNT(*) as count 
       FROM information_schema.tables 
       WHERE table_schema = DATABASE() 
       AND table_name = 'producto_ingrediente'`
    );
    
    const tableExists = (tables as Array<{ count: number }>)[0].count > 0;
    
    if (tableExists) {
      logger.info('✓ La tabla producto_ingrediente ya existe');
      return;
    }
    
    logger.info('La tabla producto_ingrediente no existe. Creándola...');
    
    // Primero, verificar el tipo de columna de producto.id
    const [productoInfo] = await connection.execute(
      `SELECT COLUMN_TYPE 
       FROM information_schema.COLUMNS 
       WHERE TABLE_SCHEMA = DATABASE() 
       AND TABLE_NAME = 'producto' 
       AND COLUMN_NAME = 'id'`
    );
    
    const productoIdType = (productoInfo as Array<{ COLUMN_TYPE: string }>)[0]?.COLUMN_TYPE || 'INT';
    const isBigInt = productoIdType.toLowerCase().includes('bigint');
    const isUnsigned = productoIdType.toLowerCase().includes('unsigned');
    
    let productoIdDef: string;
    if (isBigInt) {
      productoIdDef = isUnsigned ? 'BIGINT UNSIGNED' : 'BIGINT';
    } else {
      productoIdDef = isUnsigned ? 'INT UNSIGNED' : 'INT';
    }
    
    logger.info(`Tipo de producto.id detectado: ${productoIdType}, usando ${productoIdDef} para producto_id`);
    
    // Verificar también inventario_item.id
    const [inventarioInfo] = await connection.execute(
      `SELECT COLUMN_TYPE 
       FROM information_schema.COLUMNS 
       WHERE TABLE_SCHEMA = DATABASE() 
       AND TABLE_NAME = 'inventario_item' 
       AND COLUMN_NAME = 'id'`
    );
    
    const inventarioIdType = (inventarioInfo as Array<{ COLUMN_TYPE: string }>)[0]?.COLUMN_TYPE || 'INT';
    const isInventarioBigInt = inventarioIdType.toLowerCase().includes('bigint');
    const isInventarioUnsigned = inventarioIdType.toLowerCase().includes('unsigned');
    
    let inventarioIdDef: string;
    if (isInventarioBigInt) {
      inventarioIdDef = isInventarioUnsigned ? 'BIGINT UNSIGNED' : 'BIGINT';
    } else {
      inventarioIdDef = isInventarioUnsigned ? 'INT UNSIGNED' : 'INT';
    }
    
    logger.info(`Tipo de inventario_item.id detectado: ${inventarioIdType}, usando ${inventarioIdDef} para inventario_item_id`);
    
    // Crear la tabla usando los tipos correctos
    await connection.execute(
      `CREATE TABLE IF NOT EXISTS producto_ingrediente (
        id INT UNSIGNED NOT NULL AUTO_INCREMENT,
        producto_id ${productoIdDef} NOT NULL,
        inventario_item_id ${inventarioIdDef} NULL,
        categoria VARCHAR(64) NULL,
        nombre VARCHAR(120) NOT NULL,
        unidad VARCHAR(32) NOT NULL,
        cantidad_por_porcion DECIMAL(10,2) NOT NULL,
        descontar_automaticamente TINYINT(1) NOT NULL DEFAULT 1,
        es_personalizado TINYINT(1) NOT NULL DEFAULT 0,
        creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        CONSTRAINT fk_producto_ingrediente_producto
          FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE,
        CONSTRAINT fk_producto_ingrediente_inventario
          FOREIGN KEY (inventario_item_id) REFERENCES inventario_item(id) ON DELETE SET NULL,
        INDEX idx_producto_id (producto_id),
        INDEX idx_inventario_item_id (inventario_item_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
    );
    
    logger.info('✓ Tabla producto_ingrediente creada exitosamente');
    
  } catch (error: any) {
    logger.error({ err: error }, 'Error al crear tabla producto_ingrediente');
    throw error;
  } finally {
    if (connection) {
      connection.release();
    }
    await pool.end();
  }
}

// Ejecutar el script
crearTablaProductoIngrediente()
  .then(() => {
    logger.info('Script completado');
    process.exit(0);
  })
  .catch((error) => {
    logger.error({ err: error }, 'Error fatal en el script');
    process.exit(1);
  });

