-- Plantilla de impresión para tickets de cobro y comandas.
-- Ejecutar una sola vez en producción.

CREATE TABLE IF NOT EXISTS plantilla_impresion (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_documento VARCHAR(50) NOT NULL,
  contenido TEXT NOT NULL,
  plantilla_linea_item VARCHAR(255) NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_plantilla_tipo (tipo_documento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
