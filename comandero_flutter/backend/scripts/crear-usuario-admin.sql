-- Script para crear el usuario administrador inicial
-- NOTA: Este script SQL tiene un hash de contraseña de ejemplo.
-- Para generar el hash correcto de "Demo1234", ejecuta el script Node.js:
--   node scripts/crear-usuario-admin.js
--
-- O usa este script SQL después de generar el hash con bcrypt

-- Verificar si el usuario admin ya existe
SET @admin_exists = (SELECT COUNT(*) FROM usuario WHERE username = 'admin');

-- IMPORTANTE: Reemplaza el hash de abajo con el hash real generado por bcrypt
-- Para generar el hash, ejecuta: node scripts/crear-usuario-admin.js
SET @admin_password_hash = '$2b$10$rQZ8KJ9XvYqH8L5N3M2P1eK7J9XvYqH8L5N3M2P1eK7J9XvYqH8L5N3M2P1e'; -- Demo1234 (hash de ejemplo - NO USAR)

-- Si el usuario no existe, crearlo
INSERT INTO usuario (
    nombre,
    username,
    password_hash,
    activo,
    password_actualizada_en,
    creado_en,
    actualizado_en
)
SELECT 
    'Administrador',
    'admin',
    @admin_password_hash,
    1,
    NOW(),
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM usuario WHERE username = 'admin'
);

-- Obtener el ID del usuario admin (ya existente o recién creado)
SET @admin_id = (SELECT id FROM usuario WHERE username = 'admin' LIMIT 1);

-- Obtener el ID del rol Administrador
SET @rol_admin_id = (SELECT id FROM rol WHERE nombre = 'Administrador' LIMIT 1);

-- Asignar el rol de Administrador al usuario admin (si no lo tiene ya)
INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT @admin_id, @rol_admin_id
WHERE NOT EXISTS (
    SELECT 1 FROM usuario_rol 
    WHERE usuario_id = @admin_id AND rol_id = @rol_admin_id
);

-- Mostrar resultado
SELECT 
    'Usuario admin creado/verificado' AS mensaje,
    @admin_id AS usuario_id,
    @rol_admin_id AS rol_id;

