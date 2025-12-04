-- ============================================
-- CONSULTAS SQL PARA VER USUARIOS EN WORKBENCH
-- ============================================

-- 1. VER TODOS LOS USUARIOS CON SUS ROLES (más recientes primero)
SELECT
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo' 
        ELSE 'Inactivo' 
    END AS estado,
    u.ultimo_acceso,
    u.creado_en,
    u.actualizado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
GROUP BY u.id
ORDER BY u.id DESC;

-- 2. VER SOLO EL ÚLTIMO USUARIO CREADO (el más reciente)
SELECT
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo' 
        ELSE 'Inactivo' 
    END AS estado,
    u.ultimo_acceso,
    u.creado_en,
    u.actualizado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
GROUP BY u.id
ORDER BY u.id DESC
LIMIT 1;

-- 3. VER USUARIO ESPECÍFICO POR ID (reemplaza :id con el ID del usuario)
-- Ejemplo: WHERE u.id = 2
SELECT
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo' 
        ELSE 'Inactivo' 
    END AS estado,
    u.ultimo_acceso,
    u.creado_en,
    u.actualizado_en,
    u.password_actualizada_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles,
    GROUP_CONCAT(DISTINCT r.id ORDER BY r.id SEPARATOR ', ') AS rol_ids
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
WHERE u.id = 2  -- ⚠️ CAMBIA ESTE NÚMERO POR EL ID DEL USUARIO
GROUP BY u.id;

-- 4. VER USUARIO POR USERNAME (reemplaza 'nombre_usuario' con el username)
SELECT
    u.id,
    u.nombre,
    u.username,
    u.telefono,
    CASE 
        WHEN u.activo = 1 THEN 'Activo' 
        ELSE 'Inactivo' 
    END AS estado,
    u.ultimo_acceso,
    u.creado_en,
    u.actualizado_en,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
WHERE u.username = 'nombre_usuario'  -- ⚠️ CAMBIA ESTE USERNAME
GROUP BY u.id;

-- 5. VER DETALLES COMPLETOS DEL ÚLTIMO USUARIO (incluye password_hash)
SELECT
    u.*,
    GROUP_CONCAT(DISTINCT r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles,
    GROUP_CONCAT(DISTINCT r.id ORDER BY r.id SEPARATOR ', ') AS rol_ids
FROM usuario u
LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
LEFT JOIN rol r ON r.id = ur.rol_id
GROUP BY u.id
ORDER BY u.id DESC
LIMIT 1;

-- 6. VER SOLO LA TABLA usuario (sin roles)
SELECT * FROM usuario ORDER BY id DESC;

-- 7. VER SOLO LA TABLA usuario_rol (relación usuarios-roles)
SELECT 
    ur.*,
    u.nombre AS usuario_nombre,
    u.username,
    r.nombre AS rol_nombre
FROM usuario_rol ur
JOIN usuario u ON u.id = ur.usuario_id
JOIN rol r ON r.id = ur.rol_id
ORDER BY ur.usuario_id DESC;

-- 8. VER TODOS LOS ROLES DISPONIBLES
SELECT * FROM rol ORDER BY nombre;

