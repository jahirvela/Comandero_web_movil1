-- =============================================================================
-- APLICAR MIGRACIONES EN LOCAL (base de datos comandero)
-- =============================================================================
-- Ejecutar contra tu MySQL/MariaDB local (ej. mysql -u root -p comandero < aplicar-migraciones-local.sql)
-- Si alguna sentencia falla con "Duplicate column name" o "Duplicate key", esa
-- migración ya estaba aplicada: comenta ese bloque y vuelve a ejecutar el resto.
-- =============================================================================

USE comandero;

-- -----------------------------------------------------------------------------
-- 0) Tablas base que pueden no existir en BDs antiguas (crear si faltan)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS comanda_impresion (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NULL,
  exito TINYINT(1) NOT NULL DEFAULT 1,
  mensaje_error VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_comanda_orden (orden_id, creado_en),
  KEY ix_comanda_usuario (usuario_id),
  CONSTRAINT fk_comanda_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_comanda_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS configuracion (
  id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  iva_habilitado TINYINT(1) NOT NULL DEFAULT 0,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO configuracion (id, iva_habilitado)
SELECT 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM configuracion WHERE id = 1);

CREATE TABLE IF NOT EXISTS impresora (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  tipo ENUM('usb','tcp','bluetooth','simulation') NOT NULL DEFAULT 'usb',
  device VARCHAR(255) NULL,
  host VARCHAR(255) NULL,
  port INT UNSIGNED NULL,
  paper_width TINYINT UNSIGNED NOT NULL DEFAULT 80,
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

-- Obtener el nombre real de la FK orden_item -> producto y eliminarla (puede ser fk_item_producto, fk_orden_item_producto, etc.)
SET @fk_name = (SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'orden_item' AND REFERENCED_TABLE_NAME = 'producto' LIMIT 1);
SET @drop_fk = IF(@fk_name IS NOT NULL,
  CONCAT('ALTER TABLE orden_item DROP FOREIGN KEY `', REPLACE(@fk_name, '`', '``'), '`'),
  'SELECT 1');
PREPARE stmt_drop_fk FROM @drop_fk;
EXECUTE stmt_drop_fk;
DEALLOCATE PREPARE stmt_drop_fk;

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

-- -----------------------------------------------------------------------------
-- 8) producto: descuento por porcentaje con ventana de vigencia
-- -----------------------------------------------------------------------------
SET @sql8a = IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'producto' AND COLUMN_NAME = 'descuento_porcentaje') = 0,
  'ALTER TABLE producto ADD COLUMN descuento_porcentaje DECIMAL(5,2) NOT NULL DEFAULT 0.00 AFTER inventariable',
  'SELECT 1'
);
PREPARE stmt8a FROM @sql8a;
EXECUTE stmt8a;
DEALLOCATE PREPARE stmt8a;

SET @sql8b = IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'producto' AND COLUMN_NAME = 'descuento_inicio') = 0,
  'ALTER TABLE producto ADD COLUMN descuento_inicio DATETIME NULL AFTER descuento_porcentaje',
  'SELECT 1'
);
PREPARE stmt8b FROM @sql8b;
EXECUTE stmt8b;
DEALLOCATE PREPARE stmt8b;

SET @sql8c = IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'producto' AND COLUMN_NAME = 'descuento_fin') = 0,
  'ALTER TABLE producto ADD COLUMN descuento_fin DATETIME NULL AFTER descuento_inicio',
  'SELECT 1'
);
PREPARE stmt8c FROM @sql8c;
EXECUTE stmt8c;
DEALLOCATE PREPARE stmt8c;

-- -----------------------------------------------------------------------------
-- 9) mesa: comensales (persistido para mesero; se limpia al pasar mesa a LIBRE)
-- -----------------------------------------------------------------------------
SET @sql9 = IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mesa' AND COLUMN_NAME = 'comensales') = 0,
  'ALTER TABLE mesa ADD COLUMN comensales SMALLINT UNSIGNED NULL DEFAULT NULL COMMENT ''Personas en la mesa (informativo)'' AFTER ubicacion',
  'SELECT 1'
);
PREPARE stmt9 FROM @sql9;
EXECUTE stmt9;
DEALLOCATE PREPARE stmt9;

-- -----------------------------------------------------------------------------
-- 10) Caja por turnos y cierre del día: configuración, caja_cierre, índice fecha
--     (idempotente: seguro ejecutar en local, QA y remoto vía npm run migrate:*)
-- -----------------------------------------------------------------------------

-- Quitar UNIQUE por fecha (varios cierres/aperturas el mismo día)
SET @exist_ux := (SELECT COUNT(*) FROM information_schema.statistics
               WHERE table_schema = DATABASE()
               AND table_name = 'caja_cierre'
               AND index_name = 'ux_caja_fecha');
SET @sql_ux := IF(@exist_ux > 0,
                   'ALTER TABLE caja_cierre DROP INDEX ux_caja_fecha',
                   'SELECT 1');
PREPARE stmt_ux FROM @sql_ux;
EXECUTE stmt_ux;
DEALLOCATE PREPARE stmt_ux;

SET @exist_ixc := (SELECT COUNT(*) FROM information_schema.statistics
                WHERE table_schema = DATABASE()
                AND table_name = 'caja_cierre'
                AND index_name = 'ix_caja_fecha');
SET @sql_ixc := IF(@exist_ixc = 0,
                    'ALTER TABLE caja_cierre ADD INDEX ix_caja_fecha (fecha)',
                    'SELECT 1');
PREPARE stmt_ixc FROM @sql_ixc;
EXECUTE stmt_ixc;
DEALLOCATE PREPARE stmt_ixc;

-- configuracion: modo caja y JSON de turnos
SET @sql_caja_modo := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuracion' AND COLUMN_NAME = 'caja_modo') = 0,
  'ALTER TABLE configuracion ADD COLUMN caja_modo VARCHAR(16) NOT NULL DEFAULT ''diario'' COMMENT ''diario | turnos'' AFTER iva_habilitado',
  'SELECT 1'
);
PREPARE stmt_caja_modo FROM @sql_caja_modo;
EXECUTE stmt_caja_modo;
DEALLOCATE PREPARE stmt_caja_modo;

SET @sql_caja_tj := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuracion' AND COLUMN_NAME = 'caja_turnos_json') = 0,
  'ALTER TABLE configuracion ADD COLUMN caja_turnos_json JSON NULL COMMENT ''turnos {codigo,nombre,inicio,fin} CDMX'' AFTER caja_modo',
  'SELECT 1'
);
PREPARE stmt_caja_tj FROM @sql_caja_tj;
EXECUTE stmt_caja_tj;
DEALLOCATE PREPARE stmt_caja_tj;

-- caja_cierre: evento (apertura | cierre | cierre_dia), turno, otros ingresos declarados
SET @sql_ev := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'caja_cierre' AND COLUMN_NAME = 'evento_tipo') = 0,
  'ALTER TABLE caja_cierre ADD COLUMN evento_tipo VARCHAR(24) NULL COMMENT ''apertura | cierre | cierre_dia'' AFTER comentario_revision',
  'SELECT 1'
);
PREPARE stmt_ev FROM @sql_ev;
EXECUTE stmt_ev;
DEALLOCATE PREPARE stmt_ev;

-- Si evento_tipo ya existía como VARCHAR(16), ampliar
SET @ev_type := (SELECT COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'caja_cierre' AND COLUMN_NAME = 'evento_tipo' LIMIT 1);
SET @sql_ev_w := IF(@ev_type IS NOT NULL AND @ev_type LIKE 'varchar(16)%',
  'ALTER TABLE caja_cierre MODIFY COLUMN evento_tipo VARCHAR(24) NULL COMMENT ''apertura | cierre | cierre_dia''',
  'SELECT 1');
PREPARE stmt_ev_w FROM @sql_ev_w;
EXECUTE stmt_ev_w;
DEALLOCATE PREPARE stmt_ev_w;

SET @sql_tc := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'caja_cierre' AND COLUMN_NAME = 'turno_codigo') = 0,
  'ALTER TABLE caja_cierre ADD COLUMN turno_codigo VARCHAR(32) NULL AFTER evento_tipo',
  'SELECT 1'
);
PREPARE stmt_tc FROM @sql_tc;
EXECUTE stmt_tc;
DEALLOCATE PREPARE stmt_tc;

SET @sql_tl := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'caja_cierre' AND COLUMN_NAME = 'turno_label') = 0,
  'ALTER TABLE caja_cierre ADD COLUMN turno_label VARCHAR(120) NULL AFTER turno_codigo',
  'SELECT 1'
);
PREPARE stmt_tl FROM @sql_tl;
EXECUTE stmt_tl;
DEALLOCATE PREPARE stmt_tl;

SET @sql_oi := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'caja_cierre' AND COLUMN_NAME = 'otros_ingresos') = 0,
  'ALTER TABLE caja_cierre ADD COLUMN otros_ingresos DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER total_tarjeta',
  'SELECT 1'
);
PREPARE stmt_oi FROM @sql_oi;
EXECUTE stmt_oi;
DEALLOCATE PREPARE stmt_oi;

SET @sql_oit := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'caja_cierre' AND COLUMN_NAME = 'otros_ingresos_texto') = 0,
  'ALTER TABLE caja_cierre ADD COLUMN otros_ingresos_texto VARCHAR(500) NULL AFTER otros_ingresos',
  'SELECT 1'
);
PREPARE stmt_oit FROM @sql_oit;
EXECUTE stmt_oit;
DEALLOCATE PREPARE stmt_oit;

-- Legado: clasificar filas sin evento_tipo
UPDATE caja_cierre
SET evento_tipo = 'apertura'
WHERE (evento_tipo IS NULL OR evento_tipo = '')
  AND COALESCE(efectivo_inicial, 0) > 0
  AND (
    total_pagos IS NULL
    OR total_pagos < 1
  )
  AND COALESCE(total_efectivo, 0) + COALESCE(total_tarjeta, 0) < 1;

UPDATE caja_cierre
SET evento_tipo = 'cierre'
WHERE evento_tipo IS NULL OR evento_tipo = '';

-- =============================================================================
-- Fin de migraciones. Reinicia el backend y prueba en local.
-- =============================================================================
