-- Migración: añadir impreso_automaticamente y es_reimpresion a comanda_impresion
-- MySQL no soporta ADD COLUMN IF NOT EXISTS; usar el script TypeScript para aplicar de forma segura:
--   npx tsx scripts/run-migracion-comanda-impresion-columnas.ts
--
-- Si aplicas a mano, verifica antes que la columna no exista (information_schema.columns).

-- Ejemplo (solo si impreso_automaticamente no existe):
-- ALTER TABLE comanda_impresion
--   ADD COLUMN impreso_automaticamente BOOLEAN NOT NULL DEFAULT 1 AFTER orden_id;

-- Ejemplo (solo si es_reimpresion no existe):
-- ALTER TABLE comanda_impresion
--   ADD COLUMN es_reimpresion BOOLEAN NOT NULL DEFAULT 0 AFTER creado_en;
