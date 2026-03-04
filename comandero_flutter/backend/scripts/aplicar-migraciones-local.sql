-- =============================================================================
-- APLICAR MIGRACIONES EN LOCAL (base de datos comandero)
-- =============================================================================
-- Ejecutar contra tu MySQL/MariaDB local (ej. mysql -u root -p comandero < aplicar-migraciones-local.sql)
-- Si alguna sentencia falla con "Duplicate column name" o "Duplicate key", esa
-- migración ya estaba aplicada: comenta ese bloque y vuelve a ejecutar el resto.
-- =============================================================================

USE comandero;

-- -----------------------------------------------------------------------------
-- 1) Tabla producto_ingrediente (recetas) y columna es_opcional
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS producto_ingrediente (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  producto_id BIGINT UNSIGNED NOT NULL,
  inventario_item_id BIGINT UNSIGNED NULL,
  categoria VARCHAR(64) NULL,
  nombre VARCHAR(120) NOT NULL,
  unidad VARCHAR(32) NOT NULL,
  cantidad_por_porcion DECIMAL(10,2) NOT NULL,
  descontar_automaticamente TINYINT(1) NOT NULL DEFAULT 1,
  es_personalizado TINYINT(1) NOT NULL DEFAULT 0,
  es_opcional TINYINT(1) NOT NULL DEFAULT 0,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_producto_id (producto_id),
  KEY idx_inventario_item_id (inventario_item_id),
  CONSTRAINT fk_producto_ingrediente_producto
    FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE,
  CONSTRAINT fk_producto_ingrediente_inventario
    FOREIGN KEY (inventario_item_id) REFERENCES inventario_item(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @dbname = DATABASE();
SET @prepared = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = 'producto_ingrediente' AND COLUMN_NAME = 'es_opcional') > 0,
  'SELECT 1',
  'ALTER TABLE producto_ingrediente ADD COLUMN es_opcional TINYINT(1) NOT NULL DEFAULT 0 AFTER es_personalizado'
));
PREPARE stmt FROM @prepared;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 2) orden_item: producto_nombre, producto_tamano_etiqueta y FK ON DELETE SET NULL
-- -----------------------------------------------------------------------------
SET @col_nombre = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'orden_item' AND COLUMN_NAME = 'producto_nombre');
SET @sql2a = IF(@col_nombre = 0,
  'ALTER TABLE orden_item ADD COLUMN producto_nombre VARCHAR(255) NULL AFTER producto_tamano_id, ADD COLUMN producto_tamano_etiqueta VARCHAR(100) NULL AFTER producto_nombre',
  'SELECT 1');
PREPARE stmt2a FROM @sql2a;
EXECUTE stmt2a;
DEALLOCATE PREPARE stmt2a;

UPDATE orden_item oi
  LEFT JOIN producto p ON p.id = oi.producto_id
  LEFT JOIN producto_tamano pt ON pt.id = oi.producto_tamano_id
SET
  oi.producto_nombre = COALESCE(p.nombre, 'Producto'),
  oi.producto_tamano_etiqueta = pt.etiqueta;

ALTER TABLE orden_item
  MODIFY COLUMN producto_id BIGINT UNSIGNED NULL;

-- Si falla DROP FOREIGN KEY (ej. "check that column/key exists"), el nombre de la FK puede ser otro.
-- Ejecuta: SHOW CREATE TABLE orden_item; y sustituye abajo el nombre correcto (ej. fk_orden_item_producto).
ALTER TABLE orden_item DROP FOREIGN KEY fk_item_producto;
ALTER TABLE orden_item
  ADD CONSTRAINT fk_item_producto
  FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- 3) comanda_impresion: impreso_automaticamente, es_reimpresion
-- -----------------------------------------------------------------------------
SET @prepared2 = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'comanda_impresion' AND COLUMN_NAME = 'impreso_automaticamente') > 0,
  'SELECT 1',
  'ALTER TABLE comanda_impresion ADD COLUMN impreso_automaticamente BOOLEAN NOT NULL DEFAULT 1 AFTER orden_id'
));
PREPARE stmt2 FROM @prepared2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

SET @prepared3 = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'comanda_impresion' AND COLUMN_NAME = 'es_reimpresion') > 0,
  'SELECT 1',
  'ALTER TABLE comanda_impresion ADD COLUMN es_reimpresion BOOLEAN NOT NULL DEFAULT 0 AFTER creado_en'
));
PREPARE stmt3 FROM @prepared3;
EXECUTE stmt3;
DEALLOCATE PREPARE stmt3;

-- -----------------------------------------------------------------------------
-- 4) configuracion: columnas del cajón de dinero
-- -----------------------------------------------------------------------------
SET @cajon = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuracion' AND COLUMN_NAME = 'cajon_habilitado');
SET @sql4 = IF(@cajon = 0,
  'ALTER TABLE configuracion ADD COLUMN cajon_habilitado TINYINT(1) NOT NULL DEFAULT 0, ADD COLUMN cajon_impresora_id INT UNSIGNED NULL, ADD COLUMN cajon_abrir_efectivo TINYINT(1) NOT NULL DEFAULT 1, ADD COLUMN cajon_abrir_tarjeta TINYINT(1) NOT NULL DEFAULT 0, ADD COLUMN cajon_tipo_conexion VARCHAR(24) NOT NULL DEFAULT ''via_impresora'', ADD COLUMN cajon_marca VARCHAR(80) NULL, ADD COLUMN cajon_modelo VARCHAR(80) NULL, ADD COLUMN cajon_host VARCHAR(255) NULL, ADD COLUMN cajon_puerto INT UNSIGNED NULL, ADD COLUMN cajon_device VARCHAR(255) NULL',
  'SELECT 1');
PREPARE stmt4a FROM @sql4;
EXECUTE stmt4a;
DEALLOCATE PREPARE stmt4a;

-- -----------------------------------------------------------------------------
-- 5) Tabla plantilla_impresion (Plantilla de tickets en Admin > Configuración)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 6) impresora: impresion_remota (encolar para agente USB) y cola_impresion
-- -----------------------------------------------------------------------------
SET @prepared4 = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'impresora' AND COLUMN_NAME = 'impresion_remota') > 0,
  'SELECT 1',
  'ALTER TABLE impresora ADD COLUMN impresion_remota TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''1 = encolar en cola_impresion para agente local (USB en otro equipo)'''
));
PREPARE stmt4 FROM @prepared4;
EXECUTE stmt4;
DEALLOCATE PREPARE stmt4;

CREATE TABLE IF NOT EXISTS cola_impresion (
  id INT AUTO_INCREMENT PRIMARY KEY,
  impresora_id INT UNSIGNED NOT NULL,
  tipo_documento VARCHAR(20) NOT NULL COMMENT 'comanda | ticket',
  referencia_id INT NULL COMMENT 'orden_id para comanda/ticket',
  contenido LONGTEXT NOT NULL COMMENT 'Texto ESC/POS a imprimir',
  estado VARCHAR(20) NOT NULL DEFAULT 'pendiente' COMMENT 'pendiente | impreso | error',
  mensaje_error VARCHAR(500) NULL,
  creado_en DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  impreso_en DATETIME(3) NULL,
  KEY ix_cola_impresora_estado (impresora_id, estado),
  KEY ix_cola_creado (creado_en),
  CONSTRAINT fk_cola_impresora FOREIGN KEY (impresora_id) REFERENCES impresora(id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 7) impresora: agente_api_key (clave para agente de impresión)
-- -----------------------------------------------------------------------------
SET @prepared5 = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'impresora' AND COLUMN_NAME = 'agente_api_key') > 0,
  'SELECT 1',
  'ALTER TABLE impresora ADD COLUMN agente_api_key VARCHAR(64) NULL UNIQUE COMMENT ''Clave para el agente de impresión remota (solo cola de esta impresora)'' AFTER impresion_remota'
));
PREPARE stmt5 FROM @prepared5;
EXECUTE stmt5;
DEALLOCATE PREPARE stmt5;

-- =============================================================================
-- Fin de migraciones. Reinicia el backend y prueba en local.
-- =============================================================================
