-- ============================================
-- Script de migración: Agregar tiempo_estimado_preparacion a orden
-- ============================================
-- Permite guardar el tiempo de salida configurado por cocina

USE comandero;

SET @dbname = DATABASE();
SET @tablename = 'orden';
SET @columnname = 'tiempo_estimado_preparacion';

SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT "La columna tiempo_estimado_preparacion ya existe, no es necesario agregarla." AS resultado;',
  CONCAT(
    'ALTER TABLE ', @tablename,
    ' ADD COLUMN ', @columnname, ' INT NULL AFTER estado_orden_id'
  )
));

PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Verificar que la columna se agregó correctamente
SELECT 
  COLUMN_NAME, 
  COLUMN_TYPE, 
  IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'orden' 
  AND COLUMN_NAME = 'tiempo_estimado_preparacion';

