-- Script SQL para eliminar todas las categorías de la base de datos
-- ADVERTENCIA: Esta operación es irreversible
-- Nota: "Todos" no es una categoría real en la base de datos, es solo un filtro en la UI

-- Ver categorías antes de eliminar
SELECT id, nombre, descripcion, activo FROM categoria ORDER BY nombre;

-- Eliminar todas las categorías
DELETE FROM categoria;

-- Verificar que se eliminaron todas las categorías
SELECT COUNT(*) as categorias_restantes FROM categoria;

