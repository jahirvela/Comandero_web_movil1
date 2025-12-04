-- Script para agregar columna categoria a inventario_item si no existe
-- MySQL no soporta IF NOT EXISTS en ALTER TABLE, así que verificamos primero

-- Verificar si la columna existe
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'inventario_item'
  AND COLUMN_NAME = 'categoria';

-- Si no existe, agregarla
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE inventario_item ADD COLUMN categoria VARCHAR(64) NOT NULL DEFAULT ''Otros''',
  'SELECT ''La columna categoria ya existe'' AS mensaje'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

