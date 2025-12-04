-- Script para agregar estados de orden faltantes
-- Ejecutar con: mysql -u root -p comandero < agregar-estados-orden.sql

USE comandero;

-- Agregar estados faltantes (IGNORE evita error si ya existen)
INSERT IGNORE INTO estado_orden (nombre, descripcion) VALUES
  ('en_preparacion', 'En preparación por cocina'),
  ('listo', 'Pedido listo para servir'),
  ('listo_para_recoger', 'Pedido para llevar listo');

-- Verificar estados existentes
SELECT id, nombre, descripcion FROM estado_orden ORDER BY id;

SELECT 'Estados de orden actualizados correctamente' AS resultado;

