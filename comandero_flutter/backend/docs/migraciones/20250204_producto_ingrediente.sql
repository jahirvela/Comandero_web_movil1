-- ============================================
-- Migración: Crear tabla producto_ingrediente
-- ============================================
-- Necesaria para recetas/ingredientes de productos y para eliminar
-- productos sin error 500 (Admin → Gestión de Menú).
-- Tipos alineados con producto.id e inventario_item.id (BIGINT UNSIGNED).

USE comandero;

CREATE TABLE IF NOT EXISTS producto_ingrediente (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  producto_id BIGINT UNSIGNED NOT NULL,
  inventario_item_id BIGINT UNSIGNED NULL,
  categoria VARCHAR(64) NULL,
  nombre VARCHAR(120) NOT NULL,
  unidad VARCHAR(32) NOT NULL,
  cantidad_por_porcion DECIMAL(10,2) NOT NULL,
  descontar_automaticamente TINYINT(1) NOT NULL DEFAULT 1,
  es_personalizado TINYINT(1) NOT NULL DEFAULT 0,
  es_opcional TINYINT(1) NOT NULL DEFAULT 0,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_producto_id (producto_id),
  KEY idx_inventario_item_id (inventario_item_id),
  CONSTRAINT fk_producto_ingrediente_producto
    FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE,
  CONSTRAINT fk_producto_ingrediente_inventario
    FOREIGN KEY (inventario_item_id) REFERENCES inventario_item(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Añadir es_opcional si la tabla ya existía por una migración anterior sin esa columna
SET @dbname = DATABASE();
SET @prepared = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = 'producto_ingrediente' AND COLUMN_NAME = 'es_opcional') > 0,
  'SELECT 1',
  'ALTER TABLE producto_ingrediente ADD COLUMN es_opcional TINYINT(1) NOT NULL DEFAULT 0 AFTER es_personalizado'
));
PREPARE stmt FROM @prepared;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
