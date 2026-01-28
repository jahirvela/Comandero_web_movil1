-- Script para agregar la columna tiempo_estimado_preparacion a la tabla orden
-- Esta columna permite al cocinero establecer el tiempo estimado de preparación

ALTER TABLE orden 
ADD COLUMN IF NOT EXISTS tiempo_estimado_preparacion INT UNSIGNED NULL 
AFTER estado_orden_id;

