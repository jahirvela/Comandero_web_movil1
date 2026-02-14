-- Impresoras térmicas configurables desde el admin (USB, red, Bluetooth, simulación).
CREATE TABLE IF NOT EXISTS impresora (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  tipo ENUM('usb','tcp','bluetooth','simulation') NOT NULL DEFAULT 'usb',
  device VARCHAR(255) NULL COMMENT 'Nombre impresora (USB/Bluetooth) o ruta (simulation)',
  host VARCHAR(255) NULL COMMENT 'IP para tipo tcp',
  port INT UNSIGNED NULL COMMENT 'Puerto TCP (ej. 9100) para tipo tcp',
  paper_width TINYINT UNSIGNED NOT NULL DEFAULT 80 COMMENT '58 o 80 mm',
  imprime_ticket TINYINT(1) NOT NULL DEFAULT 1,
  imprime_comanda TINYINT(1) NOT NULL DEFAULT 0,
  orden SMALLINT NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  marca_modelo VARCHAR(120) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_impresora_activo (activo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
