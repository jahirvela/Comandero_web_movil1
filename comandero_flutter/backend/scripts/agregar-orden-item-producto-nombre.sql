-- Añade columnas producto_nombre y producto_tamano_etiqueta en orden_item.
-- Ejecutar una sola vez en la BD (ej. comandix) para evitar "Unknown column 'producto_nombre'".

-- 1. Agregar columnas
ALTER TABLE orden_item
  ADD COLUMN producto_nombre VARCHAR(255) NULL AFTER producto_tamano_id,
  ADD COLUMN producto_tamano_etiqueta VARCHAR(100) NULL AFTER producto_nombre;

-- 2. Rellenar filas existentes desde producto y producto_tamano
UPDATE orden_item oi
  LEFT JOIN producto p ON p.id = oi.producto_id
  LEFT JOIN producto_tamano pt ON pt.id = oi.producto_tamano_id
SET
  oi.producto_nombre = COALESCE(p.nombre, 'Producto'),
  oi.producto_tamano_etiqueta = pt.etiqueta;
