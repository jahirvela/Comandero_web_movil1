-- ============================================
-- CONSULTAS SQL PARA VER PRODUCTOS
-- ============================================

-- 1. Ver todos los productos con su categoría (BÁSICA)
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.descripcion,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Sí' ELSE 'No' END AS disponible,
    p.sku,
    p.creado_en,
    p.actualizado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.creado_en DESC;

-- 2. Ver productos más recientes (últimos 10)
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Sí' ELSE 'No' END AS disponible,
    p.creado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.creado_en DESC
LIMIT 10;

-- 3. Ver productos disponibles solamente
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.descripcion,
    p.precio,
    p.creado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE p.disponible = 1
ORDER BY c.nombre, p.nombre;

-- 4. Ver productos por categoría
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Sí' ELSE 'No' END AS disponible
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE c.nombre = 'Tacos'  -- Cambia 'Tacos' por la categoría que quieras
ORDER BY p.nombre;

-- 5. Ver productos con todos los detalles
SELECT 
    p.id,
    p.nombre AS producto,
    c.nombre AS categoria,
    p.descripcion,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Disponible' ELSE 'No Disponible' END AS estado,
    p.sku,
    CASE WHEN p.inventariable = 1 THEN 'Sí' ELSE 'No' END AS inventariable,
    p.creado_en AS fecha_creacion,
    p.actualizado_en AS fecha_actualizacion
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.creado_en DESC;

-- 6. Contar productos por categoría
SELECT 
    c.nombre AS categoria,
    COUNT(p.id) AS total_productos,
    COUNT(CASE WHEN p.disponible = 1 THEN 1 END) AS disponibles,
    COUNT(CASE WHEN p.disponible = 0 THEN 1 END) AS no_disponibles
FROM categoria c
LEFT JOIN producto p ON p.categoria_id = c.id
GROUP BY c.id, c.nombre
ORDER BY total_productos DESC;

-- 7. Ver productos creados hoy
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    p.creado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE DATE(p.creado_en) = CURDATE()
ORDER BY p.creado_en DESC;

-- 8. Ver productos creados en los últimos 7 días
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    p.creado_en,
    DATEDIFF(NOW(), p.creado_en) AS dias_desde_creacion
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE p.creado_en >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY p.creado_en DESC;

-- 9. Ver productos ordenados por precio (más caros primero)
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Sí' ELSE 'No' END AS disponible
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.precio DESC;

-- 10. Ver productos ordenados por precio (más baratos primero)
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Sí' ELSE 'No' END AS disponible
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.precio ASC;

-- 11. Buscar producto por nombre (búsqueda parcial)
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    p.descripcion
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE p.nombre LIKE '%Taco%'  -- Cambia 'Taco' por lo que busques
ORDER BY p.nombre;

-- 12. Ver un producto específico por ID
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    c.id AS categoria_id,
    p.descripcion,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Sí' ELSE 'No' END AS disponible,
    p.sku,
    CASE WHEN p.inventariable = 1 THEN 'Sí' ELSE 'No' END AS inventariable,
    p.creado_en,
    p.actualizado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE p.id = 1;  -- Cambia 1 por el ID del producto que busques

-- 13. Ver productos sin descripción
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE p.descripcion IS NULL OR p.descripcion = ''
ORDER BY p.nombre;

-- 14. Ver productos con SKU
SELECT 
    p.id,
    p.nombre,
    p.sku,
    c.nombre AS categoria,
    p.precio
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE p.sku IS NOT NULL AND p.sku != ''
ORDER BY p.sku;

-- 15. Ver productos inventariables
SELECT 
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    p.inventariable
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE p.inventariable = 1
ORDER BY p.nombre;

