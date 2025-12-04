# Guía de Consultas SQL para Verificar Operaciones CRUD desde Swagger

## 📋 Índice

1. [Introducción](#introducción)
2. [Módulo: Usuarios](#módulo-usuarios)
3. [Módulo: Roles](#módulo-roles)
4. [Módulo: Mesas](#módulo-mesas)
5. [Módulo: Categorías](#módulo-categorías)
6. [Módulo: Productos](#módulo-productos)
7. [Módulo: Inventario](#módulo-inventario)
8. [Módulo: Órdenes](#módulo-órdenes)
9. [Módulo: Pagos](#módulo-pagos)
10. [Consultas de Verificación Rápida](#consultas-de-verificación-rápida)

## 🔍 Introducción

Este documento contiene las consultas SQL correspondientes a cada operación CRUD disponible en Swagger. 

**Uso:**
1. Abre Swagger en `http://localhost:3000/api-docs`
2. Realiza una operación (crear, actualizar, eliminar)
3. Ejecuta la consulta SQL correspondiente en MySQL Workbench
4. Verifica que los datos se hayan guardado correctamente

## 👥 Módulo: Usuarios

### Endpoints disponibles en Swagger:
- `GET /api/usuarios` - Listar usuarios
- `GET /api/usuarios/roles/catalogo` - Listar roles disponibles
- `GET /api/usuarios/:id` - Obtener usuario por ID
- `POST /api/usuarios` - Crear usuario
- `PUT /api/usuarios/:id` - Actualizar usuario
- `DELETE /api/usuarios/:id` - Eliminar usuario
- `POST /api/usuarios/:id/roles` - Asignar roles a usuario

### Consultas SQL:

#### Después de crear un usuario (`POST /api/usuarios`):
```sql
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
    u.creado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
GROUP BY u.id
ORDER BY u.creado_en DESC
LIMIT 1;
```

#### Después de actualizar un usuario (`PUT /api/usuarios/:id`):
```sql
-- Ver usuario específico por ID (reemplazar :id con el ID del usuario)
SELECT 
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado,
    u.actualizado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
WHERE u.id = 1  -- Cambiar por el ID del usuario
GROUP BY u.id;
```

#### Después de eliminar un usuario (`DELETE /api/usuarios/:id`):
```sql
-- Ver usuarios inactivos (después de eliminar/desactivar)
SELECT 
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    u.creado_en
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
WHERE u.activo = 0
GROUP BY u.id
ORDER BY u.nombre;
```

#### Después de asignar roles (`POST /api/usuarios/:id/roles`):
```sql
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
```

## 🏷️ Módulo: Roles

### Endpoints disponibles en Swagger:
- `GET /api/roles` - Listar roles
- `GET /api/roles/:id` - Obtener rol por ID

### Consultas SQL:

#### Después de listar roles (`GET /api/roles`):
```sql
-- Ver todos los roles disponibles
SELECT 
    id,
    nombre,
    descripcion,
    creado_en,
    actualizado_en
FROM rol
ORDER BY nombre;
```

## 🪑 Módulo: Mesas

### Endpoints disponibles en Swagger:
- `GET /api/mesas` - Listar mesas
- `GET /api/mesas/estados` - Listar estados de mesa
- `GET /api/mesas/:id` - Obtener mesa por ID
- `GET /api/mesas/:id/historial` - Obtener historial de mesa
- `POST /api/mesas` - Crear mesa
- `PUT /api/mesas/:id` - Actualizar mesa
- `PATCH /api/mesas/:id/estado` - Cambiar estado de mesa
- `DELETE /api/mesas/:id` - Eliminar mesa

### Consultas SQL:

#### Después de crear una mesa (`POST /api/mesas`):
```sql
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
```

#### Después de cambiar estado de mesa (`PATCH /api/mesas/:id/estado`):
```sql
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
```

#### Después de actualizar una mesa (`PUT /api/mesas/:id`):
```sql
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
```

#### Después de eliminar una mesa (`DELETE /api/mesas/:id`):
```sql
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
```

## 📂 Módulo: Categorías

### Endpoints disponibles en Swagger:
- `GET /api/categorias` - Listar categorías
- `GET /api/categorias/:id` - Obtener categoría por ID
- `POST /api/categorias` - Crear categoría
- `PUT /api/categorias/:id` - Actualizar categoría
- `DELETE /api/categorias/:id` - Eliminar categoría

### Consultas SQL:

#### Después de crear una categoría (`POST /api/categorias`):
```sql
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
```

#### Después de actualizar una categoría (`PUT /api/categorias/:id`):
```sql
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
```

#### Después de eliminar una categoría (`DELETE /api/categorias/:id`):
```sql
-- Ver categorías inactivas (después de eliminar)
SELECT 
    id,
    nombre,
    descripcion,
    creado_en
FROM categoria
WHERE activo = 0
ORDER BY nombre;
```

## 🍽️ Módulo: Productos

### Endpoints disponibles en Swagger:
- `GET /api/productos` - Listar productos
- `GET /api/productos/:id` - Obtener producto por ID
- `POST /api/productos` - Crear producto
- `PUT /api/productos/:id` - Actualizar producto
- `DELETE /api/productos/:id` - Desactivar producto

### Consultas SQL:

#### Después de crear un producto (`POST /api/productos`):
```sql
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
```

#### Después de actualizar un producto (`PUT /api/productos/:id`):
```sql
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
```

#### Después de desactivar un producto (`DELETE /api/productos/:id`):
```sql
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
```

## 📦 Módulo: Inventario

### Endpoints disponibles en Swagger:
- `GET /api/inventario/items` - Listar items de inventario
- `GET /api/inventario/items/:id` - Obtener item por ID
- `POST /api/inventario/items` - Crear item de inventario
- `PUT /api/inventario/items/:id` - Actualizar item de inventario
- `DELETE /api/inventario/items/:id` - Eliminar item de inventario
- `GET /api/inventario/movimientos` - Listar movimientos de inventario
- `POST /api/inventario/movimientos` - Registrar movimiento de inventario

### Consultas SQL:

#### Después de crear un item de inventario (`POST /api/inventario/items`):
```sql
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
```

#### Después de actualizar un item de inventario (`PUT /api/inventario/items/:id`):
```sql
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
```

#### Después de registrar un movimiento (`POST /api/inventario/movimientos`):
```sql
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
```

#### Ver items con stock bajo:
```sql
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
```

## 📋 Módulo: Órdenes

### Endpoints disponibles en Swagger:
- `GET /api/ordenes` - Listar órdenes
- `GET /api/ordenes/estados` - Listar estados de orden
- `GET /api/ordenes/:id` - Obtener orden por ID
- `POST /api/ordenes` - Crear orden
- `PUT /api/ordenes/:id` - Actualizar orden
- `POST /api/ordenes/:id/items` - Agregar items a orden
- `PATCH /api/ordenes/:id/estado` - Cambiar estado de orden

### Consultas SQL:

#### Después de crear una orden (`POST /api/ordenes`):
```sql
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
```

#### Después de agregar items a una orden (`POST /api/ordenes/:id/items`):
```sql
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
```

#### Después de cambiar estado de orden (`PATCH /api/ordenes/:id/estado`):
```sql
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
WHERE eo.nombre = 'En Preparación'  -- Cambiar por el estado: 'Abierta', 'En Preparación', 'Lista', 'Lista para Recoger', 'Pagada', 'Cancelada'
ORDER BY o.creado_en DESC;
```

#### Ver orden completa con items:
```sql
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
```

## 💰 Módulo: Pagos

### Endpoints disponibles en Swagger:
- `GET /api/pagos` - Listar pagos
- `GET /api/pagos/formas` - Listar formas de pago
- `GET /api/pagos/propinas` - Listar propinas
- `GET /api/pagos/:id` - Obtener pago por ID
- `POST /api/pagos` - Crear pago
- `POST /api/pagos/propinas` - Registrar propina

### Consultas SQL:

#### Después de crear un pago (`POST /api/pagos`):
```sql
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
```

#### Después de registrar una propina (`POST /api/pagos/propinas`):
```sql
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
```

#### Ver pagos de una orden específica:
```sql
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
```

#### Ver formas de pago disponibles:
```sql
-- Ver todas las formas de pago disponibles
SELECT 
    id,
    nombre,
    descripcion,
    activo
FROM forma_pago
ORDER BY nombre;
```

## 🔍 Consultas de Verificación Rápida

### Ver conteo de registros por tabla:
```sql
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
```

### Ver órdenes creadas hoy:
```sql
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
```

### Ver pagos realizados hoy:
```sql
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
```

## 📝 Notas Importantes

1. **IDs dinámicos**: Reemplaza los valores `:id`, `:ordenId`, etc. con los IDs reales de tus registros.

2. **Fechas**: Las consultas que usan `CURDATE()` mostrarán solo los registros del día actual.

3. **Estados**: Los estados pueden variar según la configuración de tu base de datos. Verifica los estados disponibles antes de usar las consultas.

4. **Permisos**: Asegúrate de tener los permisos necesarios para ejecutar estas consultas en MySQL Workbench.

5. **Actualización**: Este archivo puede necesitar actualizarse si se modifican los esquemas de la base de datos.

## 🔗 Enlaces Útiles

- Swagger UI: `http://localhost:3000/api-docs`
- Health Check: `http://localhost:3000/api/health`
- Archivo SQL completo: `backend/scripts/consultas-crud-completas.sql`

## 📚 Ejemplos de Uso

### Ejemplo 1: Crear un usuario y verificar
1. Abre Swagger: `http://localhost:3000/api-docs`
2. Ve a `POST /api/usuarios`
3. Crea un usuario con los datos requeridos
4. Copia el `id` del usuario creado
5. Ejecuta en MySQL Workbench:
```sql
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
WHERE u.id = 1  -- Reemplaza con el ID del usuario creado
GROUP BY u.id;
```

### Ejemplo 2: Crear una orden y verificar
1. Abre Swagger: `http://localhost:3000/api-docs`
2. Ve a `POST /api/ordenes`
3. Crea una orden con items
4. Copia el `id` de la orden creada
5. Ejecuta en MySQL Workbench:
```sql
-- Ver la orden creada
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
WHERE o.id = 1  -- Reemplaza con el ID de la orden creada;

-- Ver los items de la orden
SELECT 
    oi.id,
    p.nombre AS producto_nombre,
    oi.cantidad,
    oi.precio_unitario,
    oi.total_linea,
    oi.nota
FROM orden_item oi
JOIN producto p ON p.id = oi.producto_id
WHERE oi.orden_id = 1  -- Reemplaza con el ID de la orden creada
ORDER BY oi.id;
```

### Ejemplo 3: Procesar un pago y verificar
1. Abre Swagger: `http://localhost:3000/api-docs`
2. Ve a `POST /api/pagos`
3. Crea un pago para una orden existente
4. Copia el `id` del pago creado
5. Ejecuta en MySQL Workbench:
```sql
-- Ver el pago creado
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
    u.nombre AS empleado_nombre
FROM pago p
JOIN orden o ON o.id = p.orden_id
LEFT JOIN mesa m ON m.id = o.mesa_id
JOIN forma_pago fp ON fp.id = p.forma_pago_id
LEFT JOIN usuario u ON u.id = p.empleado_id
WHERE p.id = 1;  -- Reemplaza con el ID del pago creado
```

## ✅ Checklist de Verificación

Después de realizar operaciones en Swagger, verifica:

- [ ] El registro se creó/actualizó/eliminó correctamente
- [ ] Los campos coinciden con los datos enviados
- [ ] Las relaciones (foreign keys) están correctas
- [ ] Las fechas de creación/actualización son correctas
- [ ] Los estados son los esperados
- [ ] Los totales y cálculos son correctos

## 🆘 Troubleshooting

### Problema: No veo los datos después de crear un registro
**Solución**: 
1. Verifica que la transacción se haya completado en el backend
2. Ejecuta `SELECT * FROM [tabla] ORDER BY creado_en DESC LIMIT 1;` para ver el último registro
3. Verifica que el `id` usado en la consulta sea correcto

### Problema: Los datos no coinciden con lo enviado
**Solución**:
1. Verifica que los datos enviados en Swagger sean correctos
2. Revisa los logs del backend para ver si hubo errores
3. Verifica que los campos en la BD coincidan con los del schema

### Problema: No puedo ver las relaciones (joins)
**Solución**:
1. Verifica que las foreign keys existan en la BD
2. Verifica que los IDs usados en los joins sean correctos
3. Usa `LEFT JOIN` en lugar de `JOIN` si algunos registros pueden no tener relación

---

**Última actualización**: 2024-01-XX
**Versión**: 1.0.0

