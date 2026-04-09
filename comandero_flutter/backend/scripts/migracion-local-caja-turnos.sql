-- =============================================================================
-- OBSOLETO: el bloque equivalente está en scripts/aplicar-migraciones-local.sql
-- (sección 10). Usa en su lugar:
--   npm run migrate:local   (.env)
--   npm run migrate:qa      (.env.qa)
--   npm run migrate:remote  (.env.remote)
-- =============================================================================

-- Configuración del restaurante: modo de caja y definición de turnos (JSON)
ALTER TABLE configuracion
  ADD COLUMN caja_modo VARCHAR(16) NOT NULL DEFAULT 'diario'
    COMMENT 'diario | turnos';

ALTER TABLE configuracion
  ADD COLUMN caja_turnos_json JSON NULL
    COMMENT 'array {codigo,nombre,inicio,fin} horario CDMX';

-- Cada fila en caja_cierre es un evento (apertura o cierre) con turno opcional
ALTER TABLE caja_cierre
  ADD COLUMN evento_tipo VARCHAR(16) NULL
    COMMENT 'apertura | cierre';

ALTER TABLE caja_cierre
  ADD COLUMN turno_codigo VARCHAR(32) NULL;

ALTER TABLE caja_cierre
  ADD COLUMN turno_label VARCHAR(120) NULL;

-- Legado: marcar aperturas donde aún no hay evento_tipo
UPDATE caja_cierre
SET evento_tipo = 'apertura'
WHERE evento_tipo IS NULL
  AND COALESCE(efectivo_inicial, 0) > 0
  AND (
    total_pagos IS NULL
    OR total_pagos < 1
  )
  AND COALESCE(total_efectivo, 0) + COALESCE(total_tarjeta, 0) < 1;

UPDATE caja_cierre
SET evento_tipo = 'cierre'
WHERE evento_tipo IS NULL;
