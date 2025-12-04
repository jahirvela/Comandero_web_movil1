-- Agregar columna de categoría al inventario (si no existe)
ALTER TABLE inventario_item
  ADD COLUMN IF NOT EXISTS categoria VARCHAR(64) NOT NULL DEFAULT 'Otros';

-- Crear tabla para ingredientes de productos
CREATE TABLE IF NOT EXISTS producto_ingrediente (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  producto_id INT UNSIGNED NOT NULL,
  inventario_item_id INT UNSIGNED NULL,
  categoria VARCHAR(64) NULL,
  nombre VARCHAR(120) NOT NULL,
  unidad VARCHAR(32) NOT NULL,
  cantidad_por_porcion DECIMAL(10,2) NOT NULL,
  descontar_automaticamente TINYINT(1) NOT NULL DEFAULT 1,
  es_personalizado TINYINT(1) NOT NULL DEFAULT 0,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_producto_ingrediente_producto
    FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE,
  CONSTRAINT fk_producto_ingrediente_inventario
    FOREIGN KEY (inventario_item_id) REFERENCES inventario_item(id) ON DELETE SET NULL
);

