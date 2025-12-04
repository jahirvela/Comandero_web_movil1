-- Script para crear la tabla de alertas si no existe
-- Ejecutar este script en MySQL Workbench si la tabla no existe

CREATE TABLE IF NOT EXISTS alerta (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo VARCHAR(50) NOT NULL COMMENT 'Tipo de alerta: alerta.demora, alerta.cancelacion, etc.',
  mensaje TEXT NOT NULL,
  orden_id BIGINT UNSIGNED NULL,
  mesa_id BIGINT UNSIGNED NULL,
  producto_id BIGINT UNSIGNED NULL,
  prioridad ENUM('baja', 'media', 'alta', 'urgente') NOT NULL DEFAULT 'media',
  estacion VARCHAR(50) NULL COMMENT 'Estación de cocina si aplica',
  creado_por_usuario_id BIGINT UNSIGNED NOT NULL,
  leido TINYINT(1) NOT NULL DEFAULT 0,
  leido_por_usuario_id BIGINT UNSIGNED NULL,
  leido_en TIMESTAMP NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_orden (orden_id),
  INDEX idx_mesa (mesa_id),
  INDEX idx_producto (producto_id),
  INDEX idx_creado_por (creado_por_usuario_id),
  INDEX idx_leido (leido),
  INDEX idx_tipo (tipo),
  INDEX idx_creado_en (creado_en),
  FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE,
  FOREIGN KEY (mesa_id) REFERENCES mesa(id) ON DELETE CASCADE,
  FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE SET NULL,
  FOREIGN KEY (creado_por_usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
  FOREIGN KEY (leido_por_usuario_id) REFERENCES usuario(id) ON DELETE SET NULL
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

