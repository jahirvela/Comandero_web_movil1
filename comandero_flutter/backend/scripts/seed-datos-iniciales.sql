-- ============================================
-- SCRIPT DE DATOS SEMILLA - Proyecto Comandero
-- ============================================
-- Ejecutar DESPUÉS de la migración de estructura (migracion-completa-bd.sql o comandero.sql)
-- Incluye todos los datos necesarios para que el sistema funcione sin errores.
-- ============================================

USE comandero;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- 1. ROLES (requeridos por requireRoles en backend)
-- ============================================
-- Los nombres deben estar en minúsculas para coincidir con el backend
INSERT IGNORE INTO rol (id, nombre, descripcion) VALUES
  (1, 'administrador', 'Acceso total al sistema'),
  (2, 'cajero', 'Gestión de caja y pagos'),
  (3, 'capitan', 'Coordinación de sala'),
  (4, 'mesero', 'Toma de órdenes'),
  (5, 'cocinero', 'Gestión de cocina y KDS');

-- ============================================
-- 2. PERMISOS (para CRUD de roles y módulos)
-- ============================================
INSERT IGNORE INTO permiso (id, nombre, descripcion) VALUES
  (1, 'ver_caja', 'Puede ver módulo de caja'),
  (2, 'cerrar_caja', 'Puede ejecutar cierre de caja'),
  (3, 'editar_menu', 'Puede administrar catálogo de productos'),
  (4, 'ver_reportes', 'Puede ver reportes del sistema'),
  (5, 'gestionar_usuarios', 'Puede gestionar usuarios y roles');

-- ============================================
-- 3. ASIGNACIÓN ROL-PERMISO
-- ============================================
-- Administrador: todos los permisos
INSERT IGNORE INTO rol_permiso (rol_id, permiso_id)
SELECT 1, p.id FROM permiso p;

-- Cajero: ver_caja y cerrar_caja
INSERT IGNORE INTO rol_permiso (rol_id, permiso_id)
SELECT 2, p.id FROM permiso p WHERE p.nombre IN ('ver_caja', 'cerrar_caja');

-- ============================================
-- 4. ESTADOS DE MESA
-- ============================================
INSERT IGNORE INTO estado_mesa (id, nombre, descripcion) VALUES
  (1, 'LIBRE', 'Disponible para asignar'),
  (2, 'OCUPADA', 'Con comensales'),
  (3, 'RESERVADA', 'Asignada por reserva'),
  (4, 'EN_LIMPIEZA', 'En servicio de limpieza');

-- ============================================
-- 5. ESTADOS DE ORDEN (usados en ordenes.service, alertas, etc.)
-- ============================================
INSERT IGNORE INTO estado_orden (id, nombre, descripcion) VALUES
  (1, 'abierta', 'Orden abierta en proceso'),
  (2, 'en_preparacion', 'En preparación por cocina'),
  (3, 'listo', 'Pedido listo para servir'),
  (4, 'listo_para_recoger', 'Pedido para llevar listo'),
  (5, 'pagada', 'Pagada y cerrada'),
  (6, 'cerrada', 'Cerrada / finalizada'),
  (7, 'cancelada', 'Cancelada');

-- ============================================
-- 6. FORMAS DE PAGO (pagos mixtos, transferencia incluida)
-- ============================================
INSERT IGNORE INTO forma_pago (id, nombre, descripcion) VALUES
  (1, 'efectivo', 'Pago en efectivo'),
  (2, 'tarjeta_debito', 'Tarjeta de débito'),
  (3, 'tarjeta_credito', 'Tarjeta de crédito'),
  (4, 'transferencia', 'Transferencia bancaria');

-- ============================================
-- 7. TABLA IMPRESORA (módulo de impresoras térmicas)
-- ============================================
CREATE TABLE IF NOT EXISTS impresora (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  tipo ENUM('usb','tcp','bluetooth','simulation') NOT NULL DEFAULT 'usb',
  device VARCHAR(255) NULL,
  host VARCHAR(255) NULL,
  port INT UNSIGNED NULL,
  paper_width TINYINT UNSIGNED NOT NULL DEFAULT 80,
  imprime_ticket TINYINT(1) NOT NULL DEFAULT 1,
  imprime_comanda TINYINT(1) NOT NULL DEFAULT 0,
  orden SMALLINT NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  marca_modelo VARCHAR(120) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_impresora_activo (activo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 8. CONFIGURACIÓN (IVA y cajón - requerido por configuracion.repository)
-- ============================================
CREATE TABLE IF NOT EXISTS configuracion (
  id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  iva_habilitado TINYINT(1) NOT NULL DEFAULT 0,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar fila por defecto
INSERT INTO configuracion (id, iva_habilitado)
SELECT 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM configuracion WHERE id = 1);

-- ============================================
-- 9. USUARIO ADMINISTRADOR INICIAL
-- ============================================
-- Contraseña: Demo1234 (hash bcrypt válido)
INSERT IGNORE INTO usuario (id, nombre, username, telefono, password_hash, password, activo, password_actualizada_en, creado_en, actualizado_en) VALUES
  (1, 'Administrador', 'admin', '555-0001', '$2b$10$iQvlAwdWmMI5dH3TZzIvee20rcQMjv9Me4l4FIAwGZY9yg6543WaK', 'Demo1234', 1, NOW(), NOW(), NOW());

-- Asignar rol de administrador al usuario admin
INSERT IGNORE INTO usuario_rol (usuario_id, rol_id) VALUES (1, 1);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- OPCIONAL: Usuarios adicionales demo
-- ============================================
-- Para crear cajero1, capitan1, mesero1, cocinero1, admincaja con contraseña Demo1234:
-- Ejecutar: npx tsx scripts/seed-users.ts

SELECT 'Datos semilla insertados correctamente. Usuario: admin | Contraseña: Demo1234' AS mensaje;
