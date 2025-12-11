-- ============================================
-- Script de migración: Agregar columna metadata a tabla alerta
-- ============================================
-- Fecha: 2025-12-11
-- Descripción: Agrega columna JSON metadata para guardar información adicional
--              como prioridad, estación, tipo de alerta, etc.
-- ============================================

USE comandero;

-- Verificar si la columna ya existe antes de agregarla
-- MySQL no soporta "IF NOT EXISTS" en ALTER TABLE ADD COLUMN,
-- así que primero verificamos si existe
SET @dbname = DATABASE();
SET @tablename = 'alerta';
SET @columnname = 'metadata';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT "La columna metadata ya existe, no es necesario agregarla." AS resultado;',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' JSON NULL COMMENT "Metadata adicional de la alerta (prioridad, estación, etc.)" AFTER creado_en;')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Verificar que la columna se agregó correctamente
SELECT 
  COLUMN_NAME, 
  COLUMN_TYPE, 
  IS_NULLABLE, 
  COLUMN_DEFAULT, 
  COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'alerta' 
  AND COLUMN_NAME = 'metadata';

-- Si prefieres ejecutar directamente sin verificación (más rápido),
-- descomenta la siguiente línea y comenta todo lo anterior:
-- ALTER TABLE alerta ADD COLUMN metadata JSON NULL COMMENT 'Metadata adicional de la alerta (prioridad, estación, etc.)' AFTER creado_en;

