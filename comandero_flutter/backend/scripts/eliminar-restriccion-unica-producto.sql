-- Script para eliminar la restricción única ux_producto_categoria_nombre
-- Esta restricción impide crear productos con el mismo nombre en la misma categoría
-- ADVERTENCIA: Esta operación es irreversible

-- Verificar si existe la restricción
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME
FROM 
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE 
    TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'producto'
    AND CONSTRAINT_NAME = 'ux_producto_categoria_nombre';

-- Eliminar la restricción única si existe
ALTER TABLE producto 
DROP INDEX IF EXISTS ux_producto_categoria_nombre;

-- Verificar que se eliminó
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME
FROM 
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE 
    TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'producto'
    AND CONSTRAINT_NAME = 'ux_producto_categoria_nombre';

