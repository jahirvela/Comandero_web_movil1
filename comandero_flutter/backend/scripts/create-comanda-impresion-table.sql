-- Script para crear la tabla comanda_impresion
-- Esta tabla rastrea las impresiones de comandas (automáticas y manuales)

CREATE TABLE IF NOT EXISTS comanda_impresion (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  impreso_automaticamente BOOLEAN NOT NULL DEFAULT 1,
  impreso_por_usuario_id BIGINT UNSIGNED NULL,
  es_reimpresion BOOLEAN NOT NULL DEFAULT 0,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_comanda_orden (orden_id),
  KEY ix_comanda_usuario (impreso_por_usuario_id),
  KEY ix_comanda_automatica (impreso_automaticamente),
  CONSTRAINT fk_comanda_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_comanda_usuario FOREIGN KEY (impreso_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

