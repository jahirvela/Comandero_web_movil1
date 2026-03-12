-- Impresoras USB en servidor remoto: encolar trabajos para que un agente en el PC los imprima
-- 1) Columna en impresora: impresion_remota = 1 para USB que imprime un agente local
-- Si la columna ya existe, omitir el siguiente ALTER (o ejecutar: ALTER TABLE impresora DROP COLUMN impresion_remota; antes)
ALTER TABLE impresora
  ADD COLUMN impresion_remota TINYINT(1) NOT NULL DEFAULT 0
  COMMENT '1 = encolar en cola_impresion para agente local (USB en otro equipo)';

-- 2) Tabla cola de impresión
CREATE TABLE IF NOT EXISTS cola_impresion (
  id INT AUTO_INCREMENT PRIMARY KEY,
  impresora_id INT NOT NULL,
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
