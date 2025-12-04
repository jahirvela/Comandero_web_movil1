-- Script SQL para eliminar todos los productos de la base de datos
-- ADVERTENCIA: Esta operación es irreversible
-- Ejecutar con cuidado en producción

-- Desactivar verificación de claves foráneas temporalmente
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Eliminar ingredientes de productos
DELETE FROM producto_ingrediente;

-- 2. Eliminar tamaños de productos
DELETE FROM producto_tamano;

-- 3. Eliminar productos
DELETE FROM producto;

-- Reactivar verificación de claves foráneas
SET FOREIGN_KEY_CHECKS = 1;

-- Verificar que se eliminaron todos los productos
SELECT COUNT(*) as productos_restantes FROM producto;
SELECT COUNT(*) as tamanos_restantes FROM producto_tamano;
SELECT COUNT(*) as ingredientes_restantes FROM producto_ingrediente;

