-- ============================================
-- Script de migración: Agregar columna producto_tamano_id a producto_ingrediente
-- ============================================
-- Permite configurar recetas por tamaño (chico, mediano, grande)

USE comandero;

-- Verificar si la columna ya existe antes de agregarla
SET @dbname = DATABASE();
SET @tablename = 'producto_ingrediente';
SET @columnname = 'producto_tamano_id';

SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT "La columna producto_tamano_id ya existe, no es necesario agregarla." AS resultado;',
  CONCAT(
    'ALTER TABLE ', @tablename,
    ' ADD COLUMN ', @columnname, ' BIGINT(20) UNSIGNED NULL AFTER producto_id,',
    ' ADD INDEX idx_producto_ingrediente_tamano (producto_tamano_id),',
    ' ADD CONSTRAINT fk_producto_ingrediente_tamano',
    ' FOREIGN KEY (producto_tamano_id) REFERENCES producto_tamano(id) ON DELETE SET NULL'
  )
));

PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Verificar que la columna se agregó correctamente
SELECT 
  COLUMN_NAME, 
  COLUMN_TYPE, 
  IS_NULLABLE,
  COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'producto_ingrediente' 
  AND COLUMN_NAME = 'producto_tamano_id';

