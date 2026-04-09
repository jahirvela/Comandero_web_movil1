-- Backfill: una entrada de kárdex por ítem que tiene stock pero nunca tuvo movimientos.
-- No modifica cantidad_actual (solo inserta historial). Idempotente si se vuelve a ejecutar.
-- Motivo acotado a VARCHAR(160) de movimiento_inventario.

INSERT INTO movimiento_inventario (
  inventario_item_id,
  tipo,
  cantidad,
  costo_unitario,
  motivo,
  origen,
  referencia_orden_id,
  creado_por_usuario_id,
  creado_en
)
SELECT
  i.id,
  'entrada',
  i.cantidad_actual,
  i.costo_unitario,
  'Stock inicial (alta) — backfill histórico',
  NULL,
  NULL,
  NULL,
  COALESCE(i.creado_en, i.actualizado_en, NOW())
FROM inventario_item i
WHERE i.activo = 1
  AND i.cantidad_actual > 0
  AND NOT EXISTS (
    SELECT 1
    FROM movimiento_inventario m
    WHERE m.inventario_item_id = i.id
    LIMIT 1
  );
