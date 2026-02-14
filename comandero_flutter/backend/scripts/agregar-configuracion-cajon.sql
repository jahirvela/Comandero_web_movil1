-- Configuración del cajón de dinero (general: marcas, modelos, tipo de conexión).
-- Ejecutar una sola vez. Tipo conexión: via_impresora | red | usb.
-- via_impresora: usa cajon_impresora_id. red: cajon_host/cajon_puerto. usb: cajon_device.
ALTER TABLE configuracion
  ADD COLUMN cajon_habilitado TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN cajon_impresora_id INT UNSIGNED NULL,
  ADD COLUMN cajon_abrir_efectivo TINYINT(1) NOT NULL DEFAULT 1,
  ADD COLUMN cajon_abrir_tarjeta TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN cajon_tipo_conexion VARCHAR(24) NOT NULL DEFAULT 'via_impresora',
  ADD COLUMN cajon_marca VARCHAR(80) NULL,
  ADD COLUMN cajon_modelo VARCHAR(80) NULL,
  ADD COLUMN cajon_host VARCHAR(255) NULL,
  ADD COLUMN cajon_puerto INT UNSIGNED NULL,
  ADD COLUMN cajon_device VARCHAR(255) NULL;
