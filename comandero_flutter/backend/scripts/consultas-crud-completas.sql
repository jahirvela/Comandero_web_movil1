-- ============================================================================
-- CONSULTAS SQL PARA VERIFICAR OPERACIONES CRUD DESDE SWAGGER
-- ============================================================================
-- Este archivo contiene consultas SQL para verificar todas las operaciones
-- CRUD realizadas desde Swagger. Organizadas por módulo y operación.
-- 
-- USO:
-- 1. Realiza una operación en Swagger (crear, actualizar, eliminar)
-- 2. Ejecuta la consulta correspondiente en MySQL Workbench
-- 3. Verifica que los datos se hayan guardado correctamente
-- ============================================================================

-- ============================================================================
-- MÓDULO: USUARIOS
-- Endpoints: /api/usuarios
-- ============================================================================

-- Ver todos los usuarios con sus roles
SELECT 
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    u.ultimo_acceso,
    u.creado_en,
    u.actualizado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
GROUP BY u.id
ORDER BY u.id DESC;

-- Ver el último usuario creado
SELECT 
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    u.ultimo_acceso,
    u.creado_en,
    u.actualizado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
GROUP BY u.id
ORDER BY u.creado_en DESC
LIMIT 1;

-- Ver un usuario específico por ID (reemplazar :id con el ID del usuario)
SELECT 
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    u.ultimo_acceso,
    u.creado_en,
    u.actualizado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
WHERE u.id = 1  -- Cambiar por el ID del usuario
GROUP BY u.id;

-- Ver usuarios por username (útil después de crear un usuario)
SELECT 
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    u.creado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
WHERE u.username = 'admin'  -- Cambiar por el username
GROUP BY u.id;

-- Ver usuarios activos
SELECT 
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    u.creado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
WHERE u.activo = 1
GROUP BY u.id
ORDER BY u.nombre;

-- Ver usuarios inactivos (después de eliminar/desactivar)
SELECT 
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    u.creado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
WHERE u.activo = 0
GROUP BY u.id
ORDER BY u.nombre;

-- Ver roles asignados a un usuario específico
SELECT 
    u.id AS usuario_id,
    u.nombre AS usuario_nombre,
    u.username,
    r.id AS rol_id,
    r.nombre AS rol_nombre,
    r.descripcion AS rol_descripcion
FROM usuario u
JOIN usuario_rol ur ON ur.usuario_id = u.id
JOIN rol r ON r.id = ur.rol_id
WHERE u.id = 1  -- Cambiar por el ID del usuario
ORDER BY r.nombre;

-- ============================================================================
-- MÓDULO: ROLES
-- Endpoints: /api/roles
-- ============================================================================

-- Ver todos los roles disponibles
SELECT 
    id,
    nombre,
    descripcion,
    creado_en,
    actualizado_en
FROM rol
ORDER BY nombre;

-- Ver un rol específico por ID
SELECT 
    id,
    nombre,
    descripcion,
    creado_en,
    actualizado_en
FROM rol
WHERE id = 1;  -- Cambiar por el ID del rol

-- Ver usuarios con un rol específico
SELECT 
    r.id AS rol_id,
    r.nombre AS rol_nombre,
    u.id AS usuario_id,
    u.nombre AS usuario_nombre,
    u.username,
    u.activo
FROM rol r
JOIN usuario_rol ur ON ur.rol_id = r.id
JOIN usuario u ON u.id = ur.usuario_id
WHERE r.id = 1  -- Cambiar por el ID del rol
ORDER BY u.nombre;

-- ============================================================================
-- MÓDULO: MESAS
-- Endpoints: /api/mesas
-- ============================================================================

-- Ver todas las mesas con su estado
SELECT 
    m.id,
    m.codigo,
    m.nombre,
    m.capacidad,
    m.ubicacion,
    em.id AS estado_id,
    em.nombre AS estado_nombre,
    CASE 
        WHEN m.activo = 1 THEN 'Activa'
        ELSE 'Inactiva'
    END AS mesa_activa,
    m.creado_en,
    m.actualizado_en
FROM mesa m
JOIN estado_mesa em ON em.id = m.estado_mesa_id
ORDER BY m.codigo;

-- Ver el último mesa creada
SELECT 
    m.id,
    m.codigo,
    m.nombre,
    m.capacidad,
    m.ubicacion,
    em.nombre AS estado_nombre,
    CASE 
        WHEN m.activo = 1 THEN 'Activa'
        ELSE 'Inactiva'
    END AS mesa_activa,
    m.creado_en,
    m.actualizado_en
FROM mesa m
JOIN estado_mesa em ON em.id = m.estado_mesa_id
ORDER BY m.creado_en DESC
LIMIT 1;

-- Ver una mesa específica por ID
SELECT 
    m.id,
    m.codigo,
    m.nombre,
    m.capacidad,
    m.ubicacion,
    em.id AS estado_id,
    em.nombre AS estado_nombre,
    CASE 
        WHEN m.activo = 1 THEN 'Activa'
        ELSE 'Inactiva'
    END AS mesa_activa,
    m.creado_en,
    m.actualizado_en
FROM mesa m
JOIN estado_mesa em ON em.id = m.estado_mesa_id
WHERE m.id = 1;  -- Cambiar por el ID de la mesa

-- Ver mesas por estado (útil después de cambiar estado)
SELECT 
    m.id,
    m.codigo,
    m.nombre,
    m.capacidad,
    m.ubicacion,
    em.nombre AS estado_nombre,
    m.actualizado_en
FROM mesa m
JOIN estado_mesa em ON em.id = m.estado_mesa_id
WHERE em.nombre = 'Ocupada'  -- Cambiar por el estado: 'Libre', 'Ocupada', 'En Limpieza', 'Reservada'
ORDER BY m.codigo;

-- Ver todos los estados de mesa disponibles
SELECT 
    id,
    nombre,
    descripcion
FROM estado_mesa
ORDER BY nombre;

-- Ver mesas activas
SELECT 
    m.id,
    m.codigo,
    m.nombre,
    m.capacidad,
    m.ubicacion,
    em.nombre AS estado_nombre
FROM mesa m
JOIN estado_mesa em ON em.id = m.estado_mesa_id
WHERE m.activo = 1
ORDER BY m.codigo;

-- Ver mesas inactivas (después de eliminar)
SELECT 
    m.id,
    m.codigo,
    m.nombre,
    m.capacidad,
    m.ubicacion,
    em.nombre AS estado_nombre,
    m.creado_en
FROM mesa m
JOIN estado_mesa em ON em.id = m.estado_mesa_id
WHERE m.activo = 0
ORDER BY m.codigo;

-- ============================================================================
-- MÓDULO: CATEGORÍAS
-- Endpoints: /api/categorias
-- ============================================================================

-- Ver todas las categorías
SELECT 
    id,
    nombre,
    descripcion,
    CASE 
        WHEN activo = 1 THEN 'Activa'
        ELSE 'Inactiva'
    END AS estado,
    creado_en,
    actualizado_en
FROM categoria
ORDER BY nombre;

-- Ver el último categoría creada
SELECT 
    id,
    nombre,
    descripcion,
    CASE 
        WHEN activo = 1 THEN 'Activa'
        ELSE 'Inactiva'
    END AS estado,
    creado_en,
    actualizado_en
FROM categoria
ORDER BY creado_en DESC
LIMIT 1;

-- Ver una categoría específica por ID
SELECT 
    id,
    nombre,
    descripcion,
    CASE 
        WHEN activo = 1 THEN 'Activa'
        ELSE 'Inactiva'
    END AS estado,
    creado_en,
    actualizado_en
FROM categoria
WHERE id = 1;  -- Cambiar por el ID de la categoría

-- Ver productos de una categoría específica
SELECT 
    c.id AS categoria_id,
    c.nombre AS categoria_nombre,
    p.id AS producto_id,
    p.nombre AS producto_nombre,
    p.precio,
    p.disponible,
    p.activo
FROM categoria c
LEFT JOIN producto p ON p.categoria_id = c.id
WHERE c.id = 1  -- Cambiar por el ID de la categoría
ORDER BY p.nombre;

-- Ver categorías activas
SELECT 
    id,
    nombre,
    descripcion,
    creado_en
FROM categoria
WHERE activo = 1
ORDER BY nombre;

-- Ver categorías inactivas (después de eliminar)
SELECT 
    id,
    nombre,
    descripcion,
    creado_en
FROM categoria
WHERE activo = 0
ORDER BY nombre;

-- ============================================================================
-- MÓDULO: PRODUCTOS
-- Endpoints: /api/productos
-- ============================================================================

-- Ver todos los productos con su categoría
SELECT 
    p.id,
    p.nombre,
    p.descripcion,
    p.precio,
    c.nombre AS categoria_nombre,
    p.sku,
    CASE 
        WHEN p.disponible = 1 THEN 'Disponible'
        ELSE 'No Disponible'
    END AS disponibilidad,
    CASE 
        WHEN p.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    p.creado_en,
    p.actualizado_en
FROM producto p
LEFT JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.nombre;

-- Ver el último producto creado
SELECT 
    p.id,
    p.nombre,
    p.descripcion,
    p.precio,
    c.nombre AS categoria_nombre,
    p.sku,
    CASE 
        WHEN p.disponible = 1 THEN 'Disponible'
        ELSE 'No Disponible'
    END AS disponibilidad,
    CASE 
        WHEN p.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    p.creado_en,
    p.actualizado_en
FROM producto p
LEFT JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.creado_en DESC
LIMIT 1;

-- Ver un producto específico por ID
SELECT 
    p.id,
    p.nombre,
    p.descripcion,
    p.precio,
    c.id AS categoria_id,
    c.nombre AS categoria_nombre,
    p.sku,
    CASE 
        WHEN p.disponible = 1 THEN 'Disponible'
        ELSE 'No Disponible'
    END AS disponibilidad,
    CASE 
        WHEN p.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    p.creado_en,
    p.actualizado_en
FROM producto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE p.id = 1;  -- Cambiar por el ID del producto

-- Ver productos por categoría
SELECT 
    p.id,
    p.nombre,
    p.descripcion,
    p.precio,
    p.sku,
    CASE 
        WHEN p.disponible = 1 THEN 'Disponible'
        ELSE 'No Disponible'
    END AS disponibilidad,
    p.creado_en
FROM producto p
WHERE p.categoria_id = 1  -- Cambiar por el ID de la categoría
ORDER BY p.nombre;

-- Ver productos disponibles
SELECT 
    p.id,
    p.nombre,
    p.descripcion,
    p.precio,
    c.nombre AS categoria_nombre,
    p.creado_en
FROM producto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE p.disponible = 1 AND p.activo = 1
ORDER BY p.nombre;

-- Ver productos no disponibles (después de desactivar)
SELECT 
    p.id,
    p.nombre,
    p.descripcion,
    p.precio,
    c.nombre AS categoria_nombre,
    p.creado_en
FROM producto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE p.disponible = 0 OR p.activo = 0
ORDER BY p.nombre;

-- ============================================================================
-- MÓDULO: INVENTARIO
-- Endpoints: /api/inventario
-- ============================================================================

-- Ver todos los items de inventario
SELECT 
    id,
    nombre,
    unidad,
    cantidad_actual,
    stock_minimo,
    costo_unitario,
    CASE 
        WHEN activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    creado_en,
    actualizado_en
FROM inventario_item
ORDER BY nombre;

-- Ver el último item de inventario creado
SELECT 
    id,
    nombre,
    unidad,
    cantidad_actual,
    stock_minimo,
    costo_unitario,
    CASE 
        WHEN activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    creado_en,
    actualizado_en
FROM inventario_item
ORDER BY creado_en DESC
LIMIT 1;

-- Ver un item de inventario específico por ID
SELECT 
    id,
    nombre,
    unidad,
    cantidad_actual,
    stock_minimo,
    costo_unitario,
    CASE 
        WHEN activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    creado_en,
    actualizado_en
FROM inventario_item
WHERE id = 1;  -- Cambiar por el ID del item

-- Ver items de inventario con stock bajo
SELECT 
    id,
    nombre,
    unidad,
    cantidad_actual,
    stock_minimo,
    (cantidad_actual - stock_minimo) AS diferencia,
    CASE 
        WHEN cantidad_actual <= stock_minimo THEN 'Stock Bajo'
        ELSE 'Stock Normal'
    END AS estado_stock,
    creado_en
FROM inventario_item
WHERE activo = 1
ORDER BY diferencia ASC;

-- Ver items de inventario activos
SELECT 
    id,
    nombre,
    unidad,
    cantidad_actual,
    stock_minimo,
    costo_unitario,
    creado_en
FROM inventario_item
WHERE activo = 1
ORDER BY nombre;

-- Ver items de inventario inactivos (después de eliminar)
SELECT 
    id,
    nombre,
    unidad,
    cantidad_actual,
    stock_minimo,
    costo_unitario,
    creado_en
FROM inventario_item
WHERE activo = 0
ORDER BY nombre;

-- Ver todos los movimientos de inventario
SELECT 
    mi.id,
    ii.nombre AS item_nombre,
    ii.unidad,
    mi.tipo,
    mi.cantidad,
    mi.costo_unitario,
    mi.motivo,
    mi.origen,
    mi.referencia_orden_id,
    u.nombre AS creado_por,
    mi.creado_en
FROM inventario_movimiento mi
JOIN inventario_item ii ON ii.id = mi.inventario_item_id
LEFT JOIN usuario u ON u.id = mi.creado_por_usuario_id
ORDER BY mi.creado_en DESC;

-- Ver el último movimiento de inventario
SELECT 
    mi.id,
    ii.nombre AS item_nombre,
    ii.unidad,
    mi.tipo,
    mi.cantidad,
    mi.costo_unitario,
    mi.motivo,
    mi.origen,
    mi.referencia_orden_id,
    u.nombre AS creado_por,
    mi.creado_en
FROM inventario_movimiento mi
JOIN inventario_item ii ON ii.id = mi.inventario_item_id
LEFT JOIN usuario u ON u.id = mi.creado_por_usuario_id
ORDER BY mi.creado_en DESC
LIMIT 1;

-- Ver movimientos de inventario de un item específico
SELECT 
    mi.id,
    mi.tipo,
    mi.cantidad,
    mi.costo_unitario,
    mi.motivo,
    mi.origen,
    mi.referencia_orden_id,
    u.nombre AS creado_por,
    mi.creado_en
FROM inventario_movimiento mi
LEFT JOIN usuario u ON u.id = mi.creado_por_usuario_id
WHERE mi.inventario_item_id = 1  -- Cambiar por el ID del item
ORDER BY mi.creado_en DESC;

-- Ver movimientos de inventario por tipo
SELECT 
    mi.id,
    ii.nombre AS item_nombre,
    mi.tipo,
    mi.cantidad,
    mi.costo_unitario,
    mi.motivo,
    mi.creado_en
FROM inventario_movimiento mi
JOIN inventario_item ii ON ii.id = mi.inventario_item_id
WHERE mi.tipo = 'entrada'  -- Cambiar por el tipo: 'entrada', 'salida', 'ajuste'
ORDER BY mi.creado_en DESC;

-- ============================================================================
-- MÓDULO: ÓRDENES
-- Endpoints: /api/ordenes
-- ============================================================================

-- Ver todas las órdenes con su estado y mesa
SELECT 
    o.id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    o.cliente_nombre,
    o.subtotal,
    o.descuento_total,
    o.impuesto_total,
    o.total,
    eo.nombre AS estado_nombre,
    u.nombre AS creado_por,
    o.creado_en,
    o.actualizado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN estado_orden eo ON eo.id = o.estado_orden_id
LEFT JOIN usuario u ON u.id = o.creado_por_usuario_id
ORDER BY o.creado_en DESC;

-- Ver la última orden creada
SELECT 
    o.id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    o.cliente_nombre,
    o.subtotal,
    o.descuento_total,
    o.impuesto_total,
    o.total,
    eo.nombre AS estado_nombre,
    u.nombre AS creado_por,
    o.creado_en,
    o.actualizado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN estado_orden eo ON eo.id = o.estado_orden_id
LEFT JOIN usuario u ON u.id = o.creado_por_usuario_id
ORDER BY o.creado_en DESC
LIMIT 1;

-- Ver una orden específica por ID
SELECT 
    o.id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    o.cliente_nombre,
    o.subtotal,
    o.descuento_total,
    o.impuesto_total,
    o.total,
    eo.nombre AS estado_nombre,
    u.nombre AS creado_por,
    o.creado_en,
    o.actualizado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN estado_orden eo ON eo.id = o.estado_orden_id
LEFT JOIN usuario u ON u.id = o.creado_por_usuario_id
WHERE o.id = 1;  -- Cambiar por el ID de la orden

-- Ver items de una orden específica
SELECT 
    oi.id,
    oi.orden_id,
    p.nombre AS producto_nombre,
    oi.cantidad,
    oi.precio_unitario,
    oi.total_linea,
    oi.nota,
    oi.creado_en
FROM orden_item oi
JOIN producto p ON p.id = oi.producto_id
WHERE oi.orden_id = 1  -- Cambiar por el ID de la orden
ORDER BY oi.id;

-- Ver órdenes por estado (útil después de cambiar estado)
SELECT 
    o.id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    o.cliente_nombre,
    o.total,
    eo.nombre AS estado_nombre,
    u.nombre AS creado_por,
    o.creado_en,
    o.actualizado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN estado_orden eo ON eo.id = o.estado_orden_id
LEFT JOIN usuario u ON u.id = o.creado_por_usuario_id
WHERE eo.nombre = 'Abierta'  -- Cambiar por el estado: 'Abierta', 'En Preparación', 'Lista', 'Lista para Recoger', 'Pagada', 'Cancelada'
ORDER BY o.creado_en DESC;

-- Ver órdenes de una mesa específica
SELECT 
    o.id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    o.cliente_nombre,
    o.total,
    eo.nombre AS estado_nombre,
    o.creado_en,
    o.actualizado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN estado_orden eo ON eo.id = o.estado_orden_id
WHERE o.mesa_id = 1  -- Cambiar por el ID de la mesa
ORDER BY o.creado_en DESC;

-- Ver órdenes para llevar (sin mesa)
SELECT 
    o.id,
    o.cliente_nombre,
    o.total,
    eo.nombre AS estado_nombre,
    u.nombre AS creado_por,
    o.creado_en,
    o.actualizado_en
FROM orden o
JOIN estado_orden eo ON eo.id = o.estado_orden_id
LEFT JOIN usuario u ON u.id = o.creado_por_usuario_id
WHERE o.mesa_id IS NULL
ORDER BY o.creado_en DESC;

-- Ver todos los estados de orden disponibles
SELECT 
    id,
    nombre,
    descripcion
FROM estado_orden
ORDER BY nombre;

-- Ver órdenes con items detallados
SELECT 
    o.id AS orden_id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    o.total AS orden_total,
    eo.nombre AS estado_nombre,
    oi.id AS item_id,
    p.nombre AS producto_nombre,
    oi.cantidad,
    oi.precio_unitario,
    oi.total_linea,
    oi.nota
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN estado_orden eo ON eo.id = o.estado_orden_id
JOIN orden_item oi ON oi.orden_id = o.id
JOIN producto p ON p.id = oi.producto_id
WHERE o.id = 1  -- Cambiar por el ID de la orden
ORDER BY oi.id;

-- Ver órdenes pendientes (no pagadas ni canceladas)
SELECT 
    o.id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    o.cliente_nombre,
    o.total,
    eo.nombre AS estado_nombre,
    o.creado_en,
    o.actualizado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN estado_orden eo ON eo.id = o.estado_orden_id
WHERE eo.nombre NOT IN ('Pagada', 'Cancelada')
ORDER BY o.creado_en DESC;

-- ============================================================================
-- MÓDULO: PAGOS
-- Endpoints: /api/pagos
-- ============================================================================

-- Ver todos los pagos con su forma de pago
SELECT 
    p.id,
    p.orden_id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    fp.nombre AS forma_pago_nombre,
    p.monto,
    p.referencia,
    p.estado,
    p.fecha_pago,
    u.nombre AS empleado_nombre,
    p.creado_en,
    p.actualizado_en
FROM pago p
JOIN orden o ON o.id = p.orden_id
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN forma_pago fp ON fp.id = p.forma_pago_id
LEFT JOIN usuario u ON u.id = p.empleado_id
ORDER BY p.fecha_pago DESC;

-- Ver el último pago registrado
SELECT 
    p.id,
    p.orden_id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    fp.nombre AS forma_pago_nombre,
    p.monto,
    p.referencia,
    p.estado,
    p.fecha_pago,
    u.nombre AS empleado_nombre,
    p.creado_en,
    p.actualizado_en
FROM pago p
JOIN orden o ON o.id = p.orden_id
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN forma_pago fp ON fp.id = p.forma_pago_id
LEFT JOIN usuario u ON u.id = p.empleado_id
ORDER BY p.creado_en DESC
LIMIT 1;

-- Ver un pago específico por ID
SELECT 
    p.id,
    p.orden_id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    fp.nombre AS forma_pago_nombre,
    p.monto,
    p.referencia,
    p.estado,
    p.fecha_pago,
    u.nombre AS empleado_nombre,
    p.creado_en,
    p.actualizado_en
FROM pago p
JOIN orden o ON o.id = p.orden_id
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN forma_pago fp ON fp.id = p.forma_pago_id
LEFT JOIN usuario u ON u.id = p.empleado_id
WHERE p.id = 1;  -- Cambiar por el ID del pago

-- Ver pagos de una orden específica
SELECT 
    p.id,
    p.orden_id,
    fp.nombre AS forma_pago_nombre,
    p.monto,
    p.referencia,
    p.estado,
    p.fecha_pago,
    u.nombre AS empleado_nombre,
    p.creado_en
FROM pago p
JOIN forma_pago fp ON fp.id = p.forma_pago_id
LEFT JOIN usuario u ON u.id = p.empleado_id
WHERE p.orden_id = 1  -- Cambiar por el ID de la orden
ORDER BY p.fecha_pago DESC;

-- Ver todas las formas de pago disponibles
SELECT 
    id,
    nombre,
    descripcion,
    activo
FROM forma_pago
ORDER BY nombre;

-- Ver pagos por forma de pago
SELECT 
    p.id,
    p.orden_id,
    fp.nombre AS forma_pago_nombre,
    p.monto,
    p.referencia,
    p.estado,
    p.fecha_pago,
    u.nombre AS empleado_nombre
FROM pago p
JOIN forma_pago fp ON fp.id = p.forma_pago_id
LEFT JOIN usuario u ON u.id = p.empleado_id
WHERE fp.nombre = 'Efectivo'  -- Cambiar por la forma de pago: 'Efectivo', 'Tarjeta', etc.
ORDER BY p.fecha_pago DESC;

-- Ver todas las propinas registradas
SELECT 
    pr.id,
    pr.orden_id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    pr.monto,
    u.nombre AS registrado_por,
    pr.fecha,
    pr.creado_en
FROM propina pr
JOIN orden o ON o.id = pr.orden_id
LEFT JOIN mesa m ON m.id = o.mesa_id
LEFT JOIN usuario u ON u.id = pr.registrado_por_usuario_id
ORDER BY pr.fecha DESC;

-- Ver la última propina registrada
SELECT 
    pr.id,
    pr.orden_id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    pr.monto,
    u.nombre AS registrado_por,
    pr.fecha,
    pr.creado_en
FROM propina pr
JOIN orden o ON o.id = pr.orden_id
LEFT JOIN mesa m ON m.id = o.mesa_id
LEFT JOIN usuario u ON u.id = pr.registrado_por_usuario_id
ORDER BY pr.creado_en DESC
LIMIT 1;

-- Ver propinas de una orden específica
SELECT 
    pr.id,
    pr.orden_id,
    pr.monto,
    u.nombre AS registrado_por,
    pr.fecha,
    pr.creado_en
FROM propina pr
LEFT JOIN usuario u ON u.id = pr.registrado_por_usuario_id
WHERE pr.orden_id = 1  -- Cambiar por el ID de la orden
ORDER BY pr.fecha DESC;

-- Ver resumen de pagos por día
SELECT 
    DATE(p.fecha_pago) AS fecha,
    COUNT(*) AS total_pagos,
    SUM(p.monto) AS total_monto,
    fp.nombre AS forma_pago_nombre
FROM pago p
JOIN forma_pago fp ON fp.id = p.forma_pago_id
GROUP BY DATE(p.fecha_pago), fp.nombre
ORDER BY fecha DESC, fp.nombre;

-- Ver resumen de propinas por día
SELECT 
    DATE(pr.fecha) AS fecha,
    COUNT(*) AS total_propinas,
    SUM(pr.monto) AS total_monto
FROM propina pr
GROUP BY DATE(pr.fecha)
ORDER BY fecha DESC;

-- ============================================================================
-- MÓDULO: TICKETS (Impresión)
-- Endpoints: /api/tickets
-- ============================================================================

-- Ver el último ticket impreso (si se guarda en BD)
-- Nota: Esto depende de si el módulo de tickets guarda registros en BD
-- Si no guarda, esta consulta no será útil

-- ============================================================================
-- MÓDULO: REPORTES
-- Endpoints: /api/reportes
-- ============================================================================

-- Ver estadísticas de ventas por día
SELECT 
    DATE(o.creado_en) AS fecha,
    COUNT(*) AS total_ordenes,
    SUM(o.total) AS total_ventas,
    AVG(o.total) AS promedio_venta
FROM orden o
WHERE o.estado_orden_id IN (
    SELECT id FROM estado_orden WHERE nombre = 'Pagada'
)
GROUP BY DATE(o.creado_en)
ORDER BY fecha DESC;

-- Ver estadísticas de ventas por producto
SELECT 
    p.id,
    p.nombre AS producto_nombre,
    COUNT(oi.id) AS total_veces_vendido,
    SUM(oi.cantidad) AS total_cantidad_vendida,
    SUM(oi.total_linea) AS total_ingresos
FROM producto p
JOIN orden_item oi ON oi.producto_id = p.id
JOIN orden o ON o.id = oi.orden_id
WHERE o.estado_orden_id IN (
    SELECT id FROM estado_orden WHERE nombre = 'Pagada'
)
GROUP BY p.id, p.nombre
ORDER BY total_ingresos DESC;

-- Ver estadísticas de ventas por categoría
SELECT 
    c.id,
    c.nombre AS categoria_nombre,
    COUNT(DISTINCT o.id) AS total_ordenes,
    SUM(oi.total_linea) AS total_ingresos
FROM categoria c
JOIN producto p ON p.categoria_id = c.id
JOIN orden_item oi ON oi.producto_id = p.id
JOIN orden o ON o.id = oi.orden_id
WHERE o.estado_orden_id IN (
    SELECT id FROM estado_orden WHERE nombre = 'Pagada'
)
GROUP BY c.id, c.nombre
ORDER BY total_ingresos DESC;

-- Ver estadísticas de ventas por mesero
SELECT 
    u.id,
    u.nombre AS mesero_nombre,
    COUNT(DISTINCT o.id) AS total_ordenes,
    SUM(o.total) AS total_ventas,
    AVG(o.total) AS promedio_venta
FROM usuario u
JOIN orden o ON o.creado_por_usuario_id = u.id
WHERE o.estado_orden_id IN (
    SELECT id FROM estado_orden WHERE nombre = 'Pagada'
)
GROUP BY u.id, u.nombre
ORDER BY total_ventas DESC;

-- ============================================================================
-- CONSULTAS DE VERIFICACIÓN RÁPIDA
-- ============================================================================

-- Ver conteo de registros por tabla
SELECT 
    'usuario' AS tabla, COUNT(*) AS total FROM usuario
UNION ALL
SELECT 
    'rol' AS tabla, COUNT(*) AS total FROM rol
UNION ALL
SELECT 
    'mesa' AS tabla, COUNT(*) AS total FROM mesa
UNION ALL
SELECT 
    'categoria' AS tabla, COUNT(*) AS total FROM categoria
UNION ALL
SELECT 
    'producto' AS tabla, COUNT(*) AS total FROM producto
UNION ALL
SELECT 
    'inventario_item' AS tabla, COUNT(*) AS total FROM inventario_item
UNION ALL
SELECT 
    'inventario_movimiento' AS tabla, COUNT(*) AS total FROM inventario_movimiento
UNION ALL
SELECT 
    'orden' AS tabla, COUNT(*) AS total FROM orden
UNION ALL
SELECT 
    'orden_item' AS tabla, COUNT(*) AS total FROM orden_item
UNION ALL
SELECT 
    'pago' AS tabla, COUNT(*) AS total FROM pago
UNION ALL
SELECT 
    'propina' AS tabla, COUNT(*) AS total FROM propina;

-- Ver las últimas 5 operaciones por tabla (útil para verificar cambios recientes)
SELECT 
    'usuario' AS tabla, id, nombre AS descripcion, creado_en FROM usuario ORDER BY creado_en DESC LIMIT 5
UNION ALL
SELECT 
    'mesa' AS tabla, id, nombre AS descripcion, creado_en FROM mesa ORDER BY creado_en DESC LIMIT 5
UNION ALL
SELECT 
    'categoria' AS tabla, id, nombre AS descripcion, creado_en FROM categoria ORDER BY creado_en DESC LIMIT 5
UNION ALL
SELECT 
    'producto' AS tabla, id, nombre AS descripcion, creado_en FROM producto ORDER BY creado_en DESC LIMIT 5
UNION ALL
SELECT 
    'inventario_item' AS tabla, id, nombre AS descripcion, creado_en FROM inventario_item ORDER BY creado_en DESC LIMIT 5
UNION ALL
SELECT 
    'orden' AS tabla, id, CONCAT('Orden #', id) AS descripcion, creado_en FROM orden ORDER BY creado_en DESC LIMIT 5
UNION ALL
SELECT 
    'pago' AS tabla, id, CONCAT('Pago #', id) AS descripcion, creado_en FROM pago ORDER BY creado_en DESC LIMIT 5;

-- Ver órdenes creadas hoy
SELECT 
    o.id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    o.cliente_nombre,
    o.total,
    eo.nombre AS estado_nombre,
    o.creado_en
FROM orden o
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN estado_orden eo ON eo.id = o.estado_orden_id
WHERE DATE(o.creado_en) = CURDATE()
ORDER BY o.creado_en DESC;

-- Ver pagos realizados hoy
SELECT 
    p.id,
    p.orden_id,
    o.mesa_id,
    m.codigo AS mesa_codigo,
    fp.nombre AS forma_pago_nombre,
    p.monto,
    p.fecha_pago,
    u.nombre AS empleado_nombre
FROM pago p
JOIN orden o ON o.id = p.orden_id
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN forma_pago fp ON fp.id = p.forma_pago_id
LEFT JOIN usuario u ON u.id = p.empleado_id
WHERE DATE(p.fecha_pago) = CURDATE()
ORDER BY p.fecha_pago DESC;

-- ============================================================================
-- CONSULTAS DE VERIFICACIÓN DE INTEGRIDAD
-- ============================================================================

-- Verificar órdenes sin items
SELECT 
    o.id,
    o.mesa_id,
    o.total,
    eo.nombre AS estado_nombre,
    o.creado_en
FROM orden o
JOIN estado_orden eo ON eo.id = o.estado_orden_id
LEFT JOIN orden_item oi ON oi.orden_id = o.id
WHERE oi.id IS NULL
ORDER BY o.creado_en DESC;

-- Verificar pagos sin orden asociada (no debería haber)
SELECT 
    p.id,
    p.orden_id,
    p.monto,
    p.fecha_pago
FROM pago p
LEFT JOIN orden o ON o.id = p.orden_id
WHERE o.id IS NULL;

-- Verificar productos sin categoría
SELECT 
    p.id,
    p.nombre,
    p.precio,
    p.creado_en
FROM producto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE c.id IS NULL
ORDER BY p.nombre;

-- Verificar items de orden sin producto
SELECT 
    oi.id,
    oi.orden_id,
    oi.producto_id,
    oi.cantidad,
    oi.creado_en
FROM orden_item oi
LEFT JOIN producto p ON p.id = oi.producto_id
WHERE p.id IS NULL
ORDER BY oi.creado_en DESC;

-- ============================================================================
-- FIN DE CONSULTAS
-- ============================================================================

