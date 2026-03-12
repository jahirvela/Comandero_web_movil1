-- Clave dedicada para el agente de impresión (alternativa al token JWT).
-- El admin genera la clave en Configuración > Impresoras; el agente la usa en el .bat.
-- No caduca y solo da acceso a la cola de esa impresora.

ALTER TABLE impresora
  ADD COLUMN agente_api_key VARCHAR(64) NULL UNIQUE
  COMMENT 'Clave para el agente de impresión remota (solo cola de esta impresora)'
  AFTER impresion_remota;
