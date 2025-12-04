-- ============================================
-- CONSULTAS SQL PARA VERIFICAR DATOS EN WORKBENCH
-- ============================================

-- ============================================
-- USUARIOS
-- ============================================
-- Ver todos los usuarios con sus roles
SELECT
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE WHEN u.activo = 1 THEN 'Activo' ELSE 'Inactivo' END AS estado,
    u.ultimo_acceso,
    u.creado_en,
    u.actualizado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
GROUP BY u.id
ORDER BY u.id DESC;

-- ============================================
-- PRODUCTOS
-- ============================================
-- Ver todos los productos con su categoría
SELECT
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.descripcion,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Disponible' ELSE 'No disponible' END AS estado,
    p.sku,
    CASE WHEN p.inventariable = 1 THEN 'Sí' ELSE 'No' END AS inventariable,
    p.creado_en,
    p.actualizado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.id DESC;

-- Ver último producto creado
SELECT
    p.id,
    p.nombre,
    c.nombre AS categoria,
    p.precio,
    CASE WHEN p.disponible = 1 THEN 'Disponible' ELSE 'No disponible' END AS estado,
    p.creado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.id DESC
LIMIT 1;

-- ============================================
-- INVENTARIO
-- ============================================
-- Ver todos los items de inventario
SELECT
    id,
    nombre,
    unidad,
    cantidad_actual,
    stock_minimo,
    costo_unitario,
    CASE WHEN activo = 1 THEN 'Activo' ELSE 'Inactivo' END AS estado,
    creado_en,
    actualizado_en
FROM inventario_item
ORDER BY id DESC;

-- Ver último item de inventario creado
SELECT
    id,
    nombre,
    unidad,
    cantidad_actual,
    stock_minimo,
    costo_unitario,
    CASE WHEN activo = 1 THEN 'Activo' ELSE 'Inactivo' END AS estado,
    creado_en
FROM inventario_item
ORDER BY id DESC
LIMIT 1;

-- Ver movimientos de inventario
SELECT
    m.id,
    i.nombre AS item,
    m.tipo,
    m.cantidad,
    m.costo_unitario,
    m.motivo,
    m.origen,
    m.creado_en
FROM inventario_movimiento m
JOIN inventario_item i ON i.id = m.inventario_item_id
ORDER BY m.id DESC
LIMIT 20;

-- ============================================
-- MESAS
-- ============================================
-- Ver todas las mesas con su estado
SELECT
    m.id,
    m.codigo,
    m.nombre,
    m.capacidad,
    m.ubicacion,
    em.nombre AS estado,
    CASE WHEN m.activo = 1 THEN 'Activa' ELSE 'Inactiva' END AS activa,
    m.creado_en,
    m.actualizado_en
FROM mesa m
LEFT JOIN estado_mesa em ON em.id = m.estado_mesa_id
ORDER BY m.id DESC;

-- Ver última mesa creada
SELECT
    m.id,
    m.codigo,
    m.nombre,
    m.capacidad,
    m.ubicacion,
    em.nombre AS estado,
    CASE WHEN m.activo = 1 THEN 'Activa' ELSE 'Inactiva' END AS activa,
    m.creado_en
FROM mesa m
LEFT JOIN estado_mesa em ON em.id = m.estado_mesa_id
ORDER BY m.id DESC
LIMIT 1;

-- ============================================
-- CATEGORÍAS
-- ============================================
-- Ver todas las categorías
SELECT
    id,
    nombre,
    descripcion,
    CASE WHEN activo = 1 THEN 'Activa' ELSE 'Inactiva' END AS estado,
    creado_en,
    actualizado_en
FROM categoria
ORDER BY id DESC;

-- Ver última categoría creada
SELECT
    id,
    nombre,
    descripcion,
    CASE WHEN activo = 1 THEN 'Activa' ELSE 'Inactiva' END AS estado,
    creado_en
FROM categoria
ORDER BY id DESC
LIMIT 1;

-- ============================================
-- ÓRDENES
-- ============================================
-- Ver todas las órdenes
SELECT
    o.id,
    o.numero,
    m.codigo AS mesa,
    o.estado,
    o.total,
    o.creado_en,
    o.actualizado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
ORDER BY o.id DESC
LIMIT 20;

-- Ver última orden creada
SELECT
    o.id,
    o.numero,
    m.codigo AS mesa,
    o.estado,
    o.total,
    o.creado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
ORDER BY o.id DESC
LIMIT 1;

-- Ver items de una orden
SELECT
    oi.id,
    o.numero AS orden,
    p.nombre AS producto,
    oi.cantidad,
    oi.precio_unitario,
    oi.subtotal,
    oi.notas
FROM orden_item oi
JOIN orden o ON o.id = oi.orden_id
JOIN producto p ON p.id = oi.producto_id
WHERE o.id = 1  -- ⚠️ CAMBIA ESTE ID
ORDER BY oi.id;

-- ============================================
-- PAGOS
-- ============================================
-- Ver todos los pagos
SELECT
    p.id,
    o.numero AS orden,
    fp.nombre AS forma_pago,
    p.monto,
    p.propina,
    p.fecha
FROM pago p
JOIN orden o ON o.id = p.orden_id
JOIN forma_pago fp ON fp.id = p.forma_pago_id
ORDER BY p.id DESC
LIMIT 20;

-- Ver último pago registrado
SELECT
    p.id,
    o.numero AS orden,
    fp.nombre AS forma_pago,
    p.monto,
    p.propina,
    p.fecha
FROM pago p
JOIN orden o ON o.id = p.orden_id
JOIN forma_pago fp ON fp.id = p.forma_pago_id
ORDER BY p.id DESC
LIMIT 1;

-- ============================================
-- RESUMEN GENERAL
-- ============================================
-- Contar registros por tabla
SELECT 
    'usuarios' AS tabla, COUNT(*) AS total FROM usuario
UNION ALL
SELECT 'productos', COUNT(*) FROM producto
UNION ALL
SELECT 'inventario_items', COUNT(*) FROM inventario_item
UNION ALL
SELECT 'mesas', COUNT(*) FROM mesa
UNION ALL
SELECT 'categorias', COUNT(*) FROM categoria
UNION ALL
SELECT 'ordenes', COUNT(*) FROM orden
UNION ALL
SELECT 'pagos', COUNT(*) FROM pago
ORDER BY tabla;

