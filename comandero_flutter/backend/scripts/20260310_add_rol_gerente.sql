-- Agregar rol Gerente (acceso operativo combinado: mesero/cajero/cocinero).
INSERT INTO rol (nombre, descripcion)
SELECT 'gerente', 'Acceso combinado a módulos de mesero, cajero y cocina'
WHERE NOT EXISTS (
  SELECT 1 FROM rol WHERE LOWER(nombre) = 'gerente'
);
