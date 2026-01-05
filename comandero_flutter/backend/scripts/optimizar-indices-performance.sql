-- Script de optimización de índices para mejorar el rendimiento del sistema
-- Ejecutar en la base de datos MySQL

-- Índices para la tabla `orden` (muy consultada)
-- Nota: estado_orden_id puede no necesitar índice si ya es FK
-- CREATE INDEX IF NOT EXISTS idx_orden_estado_orden_id ON orden(estado_orden_id);
CREATE INDEX IF NOT EXISTS idx_orden_mesa_id ON orden(mesa_id);
CREATE INDEX IF NOT EXISTS idx_orden_creado_por_usuario_id ON orden(creado_por_usuario_id);
CREATE INDEX IF NOT EXISTS idx_orden_creado_en ON orden(creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_orden_cliente_id ON orden(cliente_id);
CREATE INDEX IF NOT EXISTS idx_orden_estado_creado ON orden(estado_orden_id, creado_en DESC);

-- Índices para la tabla `pago` (consultas frecuentes para tickets y cierres)
CREATE INDEX IF NOT EXISTS idx_pago_orden_id ON pago(orden_id);
CREATE INDEX IF NOT EXISTS idx_pago_empleado_id ON pago(empleado_id);
CREATE INDEX IF NOT EXISTS idx_pago_fecha_pago ON pago(fecha_pago DESC);
CREATE INDEX IF NOT EXISTS idx_pago_estado ON pago(estado);
CREATE INDEX IF NOT EXISTS idx_pago_orden_fecha ON pago(orden_id, fecha_pago DESC);

-- Índices para la tabla `propina` (consultas agregadas frecuentes)
CREATE INDEX IF NOT EXISTS idx_propina_orden_id ON propina(orden_id);

-- Índices para la tabla `orden_item` (consultas frecuentes para detalles)
CREATE INDEX IF NOT EXISTS idx_orden_item_orden_id ON orden_item(orden_id);

-- Índices para la tabla `inventario_item` (consultas frecuentes por estado y categoría)
CREATE INDEX IF NOT EXISTS idx_inventario_item_activo ON inventario_item(activo);
CREATE INDEX IF NOT EXISTS idx_inventario_item_categoria ON inventario_item(categoria);
CREATE INDEX IF NOT EXISTS idx_inventario_item_nombre ON inventario_item(nombre);

-- Índices para la tabla `movimiento_inventario` (consultas por fecha)
-- Nota: La columna 'fecha' puede no existir en todas las versiones
CREATE INDEX IF NOT EXISTS idx_inventario_movimiento_item_id ON movimiento_inventario(inventario_item_id);
-- Los siguientes índices están comentados porque la columna 'fecha' no existe:
-- CREATE INDEX IF NOT EXISTS idx_inventario_movimiento_fecha ON movimiento_inventario(fecha DESC);
-- CREATE INDEX IF NOT EXISTS idx_inventario_movimiento_item_fecha ON movimiento_inventario(inventario_item_id, fecha DESC);

-- Índices para la tabla `alerta` (consultas por usuario y estado)
-- Nota: La columna usuario_id puede no existir, usar user_id si es necesario
-- CREATE INDEX IF NOT EXISTS idx_alerta_usuario_id ON alerta(usuario_id);
CREATE INDEX IF NOT EXISTS idx_alerta_leida ON alerta(leida);
CREATE INDEX IF NOT EXISTS idx_alerta_tipo ON alerta(tipo);
CREATE INDEX IF NOT EXISTS idx_alerta_creado_en ON alerta(creado_en DESC);
-- CREATE INDEX IF NOT EXISTS idx_alerta_usuario_leida ON alerta(usuario_id, leida, creado_en DESC);

-- Índices para la tabla `caja_cierre` (consultas por fecha)
CREATE INDEX IF NOT EXISTS idx_caja_cierre_fecha ON caja_cierre(fecha DESC);
-- CREATE INDEX IF NOT EXISTS idx_caja_cierre_usuario_id ON caja_cierre(usuario_id);
CREATE INDEX IF NOT EXISTS idx_caja_cierre_estado ON caja_cierre(estado);

-- Índices para la tabla `mesa` (consultas por estado)
CREATE INDEX IF NOT EXISTS idx_mesa_estado_mesa_id ON mesa(estado_mesa_id);

-- Índices para la tabla `bitacora_impresion` (si existe)
-- CREATE INDEX IF NOT EXISTS idx_bitacora_impresion_orden_id ON bitacora_impresion(orden_id);
-- CREATE INDEX IF NOT EXISTS idx_bitacora_impresion_exito ON bitacora_impresion(exito);
-- CREATE INDEX IF NOT EXISTS idx_bitacora_impresion_orden_exito ON bitacora_impresion(orden_id, exito, creado_en DESC);

-- Índices para la tabla `usuario` (consultas por username y activo)
CREATE INDEX IF NOT EXISTS idx_usuario_username ON usuario(username);
CREATE INDEX IF NOT EXISTS idx_usuario_activo ON usuario(activo);

-- Índices para la tabla `producto` (consultas por categoría y disponibilidad)
CREATE INDEX IF NOT EXISTS idx_producto_categoria_id ON producto(categoria_id);
CREATE INDEX IF NOT EXISTS idx_producto_disponible ON producto(disponible);
-- CREATE INDEX IF NOT EXISTS idx_producto_activo ON producto(activo);

-- Índices para la tabla `producto_ingrediente` (consultas por producto e inventario)
CREATE INDEX IF NOT EXISTS idx_producto_ingrediente_producto_id ON producto_ingrediente(producto_id);
CREATE INDEX IF NOT EXISTS idx_producto_ingrediente_inventario_item_id ON producto_ingrediente(inventario_item_id);

SELECT 'Índices de optimización creados exitosamente' AS resultado;

