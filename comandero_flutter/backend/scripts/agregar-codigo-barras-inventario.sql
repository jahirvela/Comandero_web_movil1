-- Código de barras opcional y único por ítem de inventario.
-- Un mismo código identifica toda la línea (ej. Café 5kg); al escanear se ajusta cantidad de ese ítem.
-- Ejecutar una vez en la BD (si la columna ya existe, ignorar el error).

ALTER TABLE inventario_item
ADD COLUMN codigo_barras VARCHAR(64) NULL UNIQUE
COMMENT 'Código de barras único por línea de producto'
AFTER nombre;
