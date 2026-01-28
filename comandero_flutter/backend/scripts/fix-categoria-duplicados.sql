-- Permitir categorías con nombres duplicados
-- Ejecutar una sola vez en la BD

ALTER TABLE categoria
  DROP INDEX ux_categoria_nombre;

-- Crear índice no único para búsquedas por nombre (opcional)
CREATE INDEX ix_categoria_nombre ON categoria(nombre);

