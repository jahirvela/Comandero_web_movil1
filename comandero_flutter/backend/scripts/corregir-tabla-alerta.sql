-- Script para corregir la estructura de la tabla alerta
-- La tabla alerta debe usar VARCHAR para tipo en lugar de ENUM
-- para coincidir con el código existente

USE comandero;

-- Eliminar la tabla alerta si existe con estructura incorrecta
DROP TABLE IF EXISTS alerta;

-- Crear la tabla alerta con la estructura correcta
CREATE TABLE IF NOT EXISTS alerta (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo VARCHAR(50) NOT NULL COMMENT 'Tipo de alerta: alerta.demora, alerta.cancelacion, etc.',
  mensaje VARCHAR(255) NOT NULL,
  orden_id BIGINT UNSIGNED NULL,
  mesa_id BIGINT UNSIGNED NULL,
  producto_id BIGINT UNSIGNED NULL,
  prioridad ENUM('baja','media','alta','urgente') NOT NULL DEFAULT 'media',
  estacion VARCHAR(50) NULL COMMENT 'Estación de cocina si aplica',
  usuario_origen_id BIGINT UNSIGNED NOT NULL,
  usuario_destino_id BIGINT UNSIGNED NULL,
  leida TINYINT(1) NOT NULL DEFAULT 0,
  leido_por_usuario_id BIGINT UNSIGNED NULL,
  leido_en TIMESTAMP NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_alerta_destino (usuario_destino_id, leida, creado_en),
  KEY ix_alerta_mesa (mesa_id),
  KEY ix_alerta_orden (orden_id),
  KEY ix_alerta_tipo (tipo),
  KEY ix_alerta_creado_en (creado_en),
  CONSTRAINT fk_alerta_origen FOREIGN KEY (usuario_origen_id) REFERENCES usuario(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_alerta_destino FOREIGN KEY (usuario_destino_id) REFERENCES usuario(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_alerta_mesa FOREIGN KEY (mesa_id) REFERENCES mesa(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_alerta_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_alerta_producto FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_alerta_leido_por FOREIGN KEY (leido_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla opcional para bitácora de impresión
CREATE TABLE IF NOT EXISTS bitacora_impresion (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NULL,
  exito TINYINT(1) NOT NULL DEFAULT 1,
  mensaje TEXT NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_orden (orden_id),
  INDEX idx_usuario (usuario_id),
  INDEX idx_creado_en (creado_en),
  FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE,
  FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

