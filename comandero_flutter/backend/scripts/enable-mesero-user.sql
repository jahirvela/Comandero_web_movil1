-- Script para habilitar el usuario mesero
-- Ejecutar este script si el usuario mesero está deshabilitado y no puede hacer login

UPDATE usuario
SET activo = 1, actualizado_en = NOW()
WHERE username = 'mesero';

-- Verificar que se actualizó correctamente
SELECT id, nombre, username, activo, ultimo_acceso
FROM usuario
WHERE username = 'mesero';
