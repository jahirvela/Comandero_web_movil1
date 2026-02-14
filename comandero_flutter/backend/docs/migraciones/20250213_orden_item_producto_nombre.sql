-- Permite que el administrador elimine productos sin romper tickets ni reportes.
-- Se guarda nombre del producto y tamaño en cada ítem de orden; la FK a producto pasa a ON DELETE SET NULL.

-- 1. Agregar columnas para guardar nombre y tamaño en el momento del pedido (ejecutar una sola vez)
ALTER TABLE orden_item
  ADD COLUMN producto_nombre VARCHAR(255) NULL AFTER producto_tamano_id,
  ADD COLUMN producto_tamano_etiqueta VARCHAR(100) NULL AFTER producto_nombre;

-- 2. Rellenar datos existentes desde producto y producto_tamano
UPDATE orden_item oi
  LEFT JOIN producto p ON p.id = oi.producto_id
  LEFT JOIN producto_tamano pt ON pt.id = oi.producto_tamano_id
SET
  oi.producto_nombre = COALESCE(p.nombre, 'Producto'),
  oi.producto_tamano_etiqueta = pt.etiqueta;

-- 3. Hacer NOT NULL producto_nombre donde ya tiene valor (opcional: dejar NULL para compatibilidad)
-- 4. Permitir producto_id NULL y cambiar FK a ON DELETE SET NULL
ALTER TABLE orden_item
  MODIFY COLUMN producto_id BIGINT UNSIGNED NULL;

ALTER TABLE orden_item
  DROP FOREIGN KEY fk_item_producto;

ALTER TABLE orden_item
  ADD CONSTRAINT fk_item_producto
  FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE ON DELETE SET NULL;
