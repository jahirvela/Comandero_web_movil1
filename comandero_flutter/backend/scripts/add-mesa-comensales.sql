-- Comensales en mesa (idempotente: seguro ejecutar varias veces)
-- Uso manual: mysql -u USER -p DATABASE < scripts/add-mesa-comensales.sql

SET @sql9 = IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mesa' AND COLUMN_NAME = 'comensales') = 0,
  'ALTER TABLE mesa ADD COLUMN comensales SMALLINT UNSIGNED NULL DEFAULT NULL COMMENT ''Personas en la mesa (informativo)'' AFTER ubicacion',
  'SELECT 1'
);
PREPARE stmt9 FROM @sql9;
EXECUTE stmt9;
DEALLOCATE PREPARE stmt9;
