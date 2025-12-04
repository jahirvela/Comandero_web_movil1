-- Script para eliminar la restricción UNIQUE de fecha en caja_cierre
-- Esto permite múltiples cierres de caja el mismo día
-- Ejecuta este script en tu base de datos MySQL

-- Eliminar la restricción UNIQUE existente (compatible con todas las versiones de MySQL)
SET @exist := (SELECT COUNT(*) FROM information_schema.statistics 
               WHERE table_schema = DATABASE() 
               AND table_name = 'caja_cierre' 
               AND index_name = 'ux_caja_fecha');

SET @sqlstmt := IF(@exist > 0, 
                   'ALTER TABLE caja_cierre DROP INDEX ux_caja_fecha', 
                   'SELECT "El índice ux_caja_fecha no existe" AS message');

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Agregar un índice normal (no único) en fecha para mejorar las consultas
SET @exist2 := (SELECT COUNT(*) FROM information_schema.statistics 
                WHERE table_schema = DATABASE() 
                AND table_name = 'caja_cierre' 
                AND index_name = 'ix_caja_fecha');

SET @sqlstmt2 := IF(@exist2 = 0, 
                    'ALTER TABLE caja_cierre ADD INDEX ix_caja_fecha (fecha)', 
                    'SELECT "El índice ix_caja_fecha ya existe" AS message');

PREPARE stmt2 FROM @sqlstmt2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- Verificar que la restricción fue eliminada
SHOW INDEX FROM caja_cierre WHERE Key_name = 'ux_caja_fecha';

-- Mostrar todos los índices de la tabla para verificar
SHOW INDEX FROM caja_cierre;

