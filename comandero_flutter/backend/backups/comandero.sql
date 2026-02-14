-- ============================================
-- SCRIPT COMPLETO DE BASE DE DATOS COMANDERO
-- ============================================
-- Este script permite recrear la base de datos completa
-- Incluye estructura y datos iniciales necesarios
-- ============================================
-- Fecha de creación: 2025-01-26
-- Versión: 1.1
-- ============================================

-- Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS comandero CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE comandero;

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- ETAPA 1: Crear tabla usuario (debe existir primero)
-- ============================================
CREATE TABLE IF NOT EXISTS usuario (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(160) NOT NULL,
  username VARCHAR(80) NOT NULL,
  telefono VARCHAR(40) NULL,
  password_hash VARCHAR(255) NOT NULL,
  password VARCHAR(255) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  ultimo_acceso TIMESTAMP NULL,
  password_actualizada_en TIMESTAMP NULL,
  password_actualizada_por_usuario_id BIGINT UNSIGNED NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_usuario_username (username),
  KEY ix_usuario_activo (activo),
  KEY ix_usuario_ultimo_acceso (ultimo_acceso)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 2: Crear tablas de usuarios/roles/permisos
-- ============================================
CREATE TABLE IF NOT EXISTS rol (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(80) NOT NULL,
  descripcion VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_rol_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permiso (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_permiso_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS usuario_rol (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  rol_id BIGINT UNSIGNED NOT NULL,
  asignado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_usuario_rol (usuario_id, rol_id),
  KEY ix_usuario_rol_usuario (usuario_id),
  KEY ix_usuario_rol_rol (rol_id),
  CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_usuario_rol_rol FOREIGN KEY (rol_id) REFERENCES rol(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rol_permiso (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rol_id BIGINT UNSIGNED NOT NULL,
  permiso_id BIGINT UNSIGNED NOT NULL,
  asignado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_rol_permiso (rol_id, permiso_id),
  KEY ix_rol_permiso_rol (rol_id),
  KEY ix_rol_permiso_permiso (permiso_id),
  CONSTRAINT fk_rol_permiso_rol FOREIGN KEY (rol_id) REFERENCES rol(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_rol_permiso_permiso FOREIGN KEY (permiso_id) REFERENCES permiso(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS usuario_password_hist (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  cambiado_por_usuario_id BIGINT UNSIGNED NOT NULL,
  metodo ENUM('admin_cambio','admin_reset','creacion') NOT NULL DEFAULT 'admin_cambio',
  notas VARCHAR(255) NULL,
  ip VARCHAR(64) NULL,
  user_agent VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_uph_usuario (usuario_id, creado_en),
  KEY ix_uph_admin (cambiado_por_usuario_id, creado_en),
  CONSTRAINT fk_uph_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_uph_admin FOREIGN KEY (cambiado_por_usuario_id) REFERENCES usuario(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 3: Catálogos de estados y formas de pago
-- ============================================
CREATE TABLE IF NOT EXISTS estado_mesa (
  id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(40) NOT NULL,
  descripcion VARCHAR(120) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_estado_mesa_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS estado_orden (
  id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(40) NOT NULL,
  descripcion VARCHAR(120) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_estado_orden_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forma_pago (
  id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(40) NOT NULL,
  descripcion VARCHAR(120) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_forma_pago_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 4: Mesas / Reservas / Historial
-- ============================================
CREATE TABLE IF NOT EXISTS mesa (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo VARCHAR(40) NOT NULL,
  nombre VARCHAR(80) NULL,
  capacidad SMALLINT UNSIGNED NULL,
  ubicacion VARCHAR(120) NULL,
  estado_mesa_id TINYINT UNSIGNED NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_mesa_codigo (codigo),
  KEY ix_mesa_estado (estado_mesa_id),
  CONSTRAINT fk_mesa_estado FOREIGN KEY (estado_mesa_id) REFERENCES estado_mesa(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cliente (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(160) NOT NULL,
  telefono VARCHAR(40) NULL,
  email VARCHAR(190) NULL,
  notas VARCHAR(255) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_cliente_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reserva (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  mesa_id BIGINT UNSIGNED NOT NULL,
  nombre_cliente VARCHAR(120) NULL,
  telefono VARCHAR(40) NULL,
  fecha_hora_inicio DATETIME NOT NULL,
  fecha_hora_fin DATETIME NULL,
  estado ENUM('pendiente','confirmada','cancelada','no_show') NOT NULL DEFAULT 'pendiente',
  creado_por_usuario_id BIGINT UNSIGNED NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_reserva_mesa (mesa_id, fecha_hora_inicio),
  KEY ix_reserva_usuario (creado_por_usuario_id),
  CONSTRAINT fk_reserva_mesa FOREIGN KEY (mesa_id) REFERENCES mesa(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_reserva_usuario FOREIGN KEY (creado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mesa_estado_hist (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  mesa_id BIGINT UNSIGNED NOT NULL,
  estado_mesa_id TINYINT UNSIGNED NOT NULL,
  cambiado_por_usuario_id BIGINT UNSIGNED NULL,
  nota VARCHAR(255) NULL,
  cambiado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_meh_mesa (mesa_id, cambiado_en),
  KEY ix_meh_estado (estado_mesa_id),
  KEY ix_meh_usuario (cambiado_por_usuario_id),
  CONSTRAINT fk_meh_mesa FOREIGN KEY (mesa_id) REFERENCES mesa(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_meh_estado FOREIGN KEY (estado_mesa_id) REFERENCES estado_mesa(id) ON UPDATE CASCADE,
  CONSTRAINT fk_meh_usuario FOREIGN KEY (cambiado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 5: Productos / Inventario / Modificadores
-- ============================================
CREATE TABLE IF NOT EXISTS categoria (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(255) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_categoria_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(160) NOT NULL,
  descripcion TEXT NULL,
  precio DECIMAL(10,2) NOT NULL,
  disponible TINYINT(1) NOT NULL DEFAULT 1,
  sku VARCHAR(64) NULL,
  inventariable TINYINT(1) NOT NULL DEFAULT 0,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_producto_categoria_nombre (categoria_id, nombre),
  KEY ix_producto_categoria (categoria_id),
  CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id) REFERENCES categoria(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventario_item (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(160) NOT NULL,
  unidad VARCHAR(32) NOT NULL,
  cantidad_actual DECIMAL(12,3) NOT NULL DEFAULT 0,
  stock_minimo DECIMAL(12,3) NOT NULL DEFAULT 0,
  costo_unitario DECIMAL(12,4) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_inventario_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_insumo (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  producto_id BIGINT UNSIGNED NOT NULL,
  inventario_item_id BIGINT UNSIGNED NOT NULL,
  cantidad_porcion DECIMAL(12,3) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_producto_insumo (producto_id, inventario_item_id),
  KEY ix_pi_producto (producto_id),
  KEY ix_pi_insumo (inventario_item_id),
  CONSTRAINT fk_pi_producto FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pi_insumo FOREIGN KEY (inventario_item_id) REFERENCES inventario_item(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_tamano (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  producto_id BIGINT UNSIGNED NOT NULL,
  etiqueta VARCHAR(60) NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_pt_producto_etiqueta (producto_id, etiqueta),
  KEY ix_pt_producto (producto_id),
  CONSTRAINT fk_pt_producto FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS modificador_categoria (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(80) NOT NULL,
  obligatorio TINYINT(1) NOT NULL DEFAULT 0,
  max_opciones TINYINT UNSIGNED NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_modcat_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS modificador_opcion (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(255) NULL,
  precio DECIMAL(10,2) NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_modopc_cat_nombre (categoria_id, nombre),
  KEY ix_modopc_cat (categoria_id),
  CONSTRAINT fk_modopc_cat FOREIGN KEY (categoria_id) REFERENCES modificador_categoria(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_modificador (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  producto_id BIGINT UNSIGNED NOT NULL,
  categoria_id BIGINT UNSIGNED NOT NULL,
  obligatorio TINYINT(1) NOT NULL DEFAULT 0,
  max_opciones TINYINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_prod_mod (producto_id, categoria_id),
  KEY ix_pm_producto (producto_id),
  KEY ix_pm_categoria (categoria_id),
  CONSTRAINT fk_pm_producto FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pm_categoria FOREIGN KEY (categoria_id) REFERENCES modificador_categoria(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS modificador_insumo (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  modificador_opcion_id BIGINT UNSIGNED NOT NULL,
  inventario_item_id BIGINT UNSIGNED NOT NULL,
  cantidad_porcion DECIMAL(12,3) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_modins_opcion_item (modificador_opcion_id, inventario_item_id),
  CONSTRAINT fk_modins_opcion FOREIGN KEY (modificador_opcion_id) REFERENCES modificador_opcion(id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_modins_item FOREIGN KEY (inventario_item_id) REFERENCES inventario_item(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 6: Órdenes, items, KDS, notas, cancelación
-- ============================================
CREATE TABLE IF NOT EXISTS orden (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  mesa_id BIGINT UNSIGNED NULL,
  reserva_id BIGINT UNSIGNED NULL,
  cliente_id BIGINT UNSIGNED NULL,
  cliente_nombre VARCHAR(160) NULL,
  cliente_telefono VARCHAR(40) NULL,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
  descuento_total DECIMAL(12,2) NOT NULL DEFAULT 0,
  impuesto_total DECIMAL(12,2) NOT NULL DEFAULT 0,
  propina_sugerida DECIMAL(12,2) NULL,
  tiempo_estimado_preparacion INT UNSIGNED NULL,
  total DECIMAL(12,2) NOT NULL DEFAULT 0,
  estado_orden_id TINYINT UNSIGNED NOT NULL,
  creado_por_usuario_id BIGINT UNSIGNED NULL,
  cerrado_por_usuario_id BIGINT UNSIGNED NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_orden_mesa (mesa_id),
  KEY ix_orden_reserva (reserva_id),
  KEY ix_orden_cliente (cliente_id),
  KEY ix_orden_estado (estado_orden_id),
  KEY ix_orden_usuario (creado_por_usuario_id),
  CONSTRAINT fk_orden_mesa FOREIGN KEY (mesa_id) REFERENCES mesa(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_orden_reserva FOREIGN KEY (reserva_id) REFERENCES reserva(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_orden_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_orden_estado FOREIGN KEY (estado_orden_id) REFERENCES estado_orden(id) ON UPDATE CASCADE,
  CONSTRAINT fk_orden_creado_por FOREIGN KEY (creado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE,
  CONSTRAINT fk_orden_cerrado_por FOREIGN KEY (cerrado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orden_item (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  producto_id BIGINT UNSIGNED NOT NULL,
  producto_tamano_id BIGINT UNSIGNED NULL,
  cantidad DECIMAL(8,3) NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  total_linea DECIMAL(12,2) AS (cantidad * precio_unitario) STORED,
  nota VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_item_orden (orden_id),
  KEY ix_item_producto (producto_id),
  KEY ix_item_tamano (producto_tamano_id),
  CONSTRAINT fk_item_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_item_producto FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE,
  CONSTRAINT fk_item_tamano FOREIGN KEY (producto_tamano_id) REFERENCES producto_tamano(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS nota_orden (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  texto TEXT NOT NULL,
  creado_por_usuario_id BIGINT UNSIGNED NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_nota_orden (orden_id, creado_en),
  CONSTRAINT fk_nota_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_nota_usuario FOREIGN KEY (creado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orden_cancelacion (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  motivo VARCHAR(255) NULL,
  cancelado_por_usuario_id BIGINT UNSIGNED NULL,
  cancelado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_cancelacion_orden (orden_id),
  KEY ix_cancelacion_usuario (cancelado_por_usuario_id),
  CONSTRAINT fk_cancelacion_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_cancelacion_usuario FOREIGN KEY (cancelado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS preparacion_orden (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  orden_item_id BIGINT UNSIGNED NULL,
  asignado_a_usuario_id BIGINT UNSIGNED NULL,
  estado_preparacion ENUM('pendiente','en_preparacion','listo','entregado','cancelado') NOT NULL DEFAULT 'pendiente',
  prioridad TINYINT UNSIGNED NULL,
  tiempo_inicio DATETIME NULL,
  tiempo_fin DATETIME NULL,
  notas VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_prep_orden (orden_id),
  KEY ix_prep_item (orden_item_id),
  KEY ix_prep_asignado (asignado_a_usuario_id),
  CONSTRAINT fk_prep_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_prep_item FOREIGN KEY (orden_item_id) REFERENCES orden_item(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_prep_usuario FOREIGN KEY (asignado_a_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orden_item_modificador (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_item_id BIGINT UNSIGNED NOT NULL,
  modificador_opcion_id BIGINT UNSIGNED NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY ux_item_opcion (orden_item_id, modificador_opcion_id),
  KEY ix_oim_item (orden_item_id),
  KEY ix_oim_opcion (modificador_opcion_id),
  CONSTRAINT fk_oim_item FOREIGN KEY (orden_item_id) REFERENCES orden_item(id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_oim_opcion FOREIGN KEY (modificador_opcion_id) REFERENCES modificador_opcion(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 7: Inventario: movimientos manuales
-- ============================================
CREATE TABLE IF NOT EXISTS movimiento_inventario (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  inventario_item_id BIGINT UNSIGNED NOT NULL,
  tipo ENUM('entrada','salida','ajuste') NOT NULL,
  cantidad DECIMAL(12,3) NOT NULL,
  costo_unitario DECIMAL(12,4) NULL,
  motivo VARCHAR(160) NULL,
  origen ENUM('compra','consumo','ajuste','devolucion') NULL,
  referencia_orden_id BIGINT UNSIGNED NULL,
  creado_por_usuario_id BIGINT UNSIGNED NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_movi_item (inventario_item_id, creado_en),
  KEY ix_movi_orden (referencia_orden_id),
  KEY ix_movi_usuario (creado_por_usuario_id),
  CONSTRAINT fk_movi_item FOREIGN KEY (inventario_item_id) REFERENCES inventario_item(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_movi_orden FOREIGN KEY (referencia_orden_id) REFERENCES orden(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_movi_usuario FOREIGN KEY (creado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 8: Caja / Pagos / Propinas / Terminales / Comprobantes
-- ============================================
CREATE TABLE IF NOT EXISTS caja_cierre (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  fecha DATE NOT NULL,
  efectivo_inicial DECIMAL(12,2) NOT NULL DEFAULT 0,
  efectivo_final DECIMAL(12,2) NULL,
  total_pagos DECIMAL(12,2) NULL,
  total_efectivo DECIMAL(12,2) NULL,
  total_tarjeta DECIMAL(12,2) NULL,
  creado_por_usuario_id BIGINT UNSIGNED NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notas VARCHAR(255) NULL,
  estado VARCHAR(20) NOT NULL DEFAULT 'pending',
  revisado_por_usuario_id BIGINT UNSIGNED NULL,
  revisado_en TIMESTAMP NULL,
  comentario_revision TEXT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_caja_fecha (fecha),
  KEY ix_caja_usuario (creado_por_usuario_id),
  KEY ix_caja_fecha (fecha),
  KEY ix_caja_revisado_por (revisado_por_usuario_id),
  CONSTRAINT fk_caja_usuario FOREIGN KEY (creado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pago (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  forma_pago_id TINYINT UNSIGNED NOT NULL,
  monto DECIMAL(12,2) NOT NULL,
  referencia VARCHAR(120) NULL,
  estado ENUM('aplicado','anulado','pendiente') NOT NULL DEFAULT 'aplicado',
  fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  empleado_id BIGINT UNSIGNED NULL,
  caja_cierre_id BIGINT UNSIGNED NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_pago_orden (orden_id),
  KEY ix_pago_forma (forma_pago_id),
  KEY ix_pago_caja (caja_cierre_id),
  KEY ix_pago_empleado (empleado_id),
  CONSTRAINT fk_pago_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pago_forma FOREIGN KEY (forma_pago_id) REFERENCES forma_pago(id) ON UPDATE CASCADE,
  CONSTRAINT fk_pago_empleado FOREIGN KEY (empleado_id) REFERENCES usuario(id) ON UPDATE CASCADE,
  CONSTRAINT fk_pago_caja FOREIGN KEY (caja_cierre_id) REFERENCES caja_cierre(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS terminal (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  modelo VARCHAR(80) NULL,
  ubicacion VARCHAR(120) NULL,
  numero_serie VARCHAR(120) NULL,
  activo TINYINT NOT NULL DEFAULT 1,
  conectado TINYINT NOT NULL DEFAULT 0,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_terminal_serie (numero_serie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS terminal_log (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  terminal_id BIGINT UNSIGNED NOT NULL,
  tipo ENUM('info','warn','error') NOT NULL DEFAULT 'info',
  mensaje VARCHAR(255) NOT NULL,
  payload JSON NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_tlog_terminal (terminal_id, creado_en),
  CONSTRAINT fk_tlog_terminal FOREIGN KEY (terminal_id)
    REFERENCES terminal(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS comprobante_tarjeta (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pago_id BIGINT UNSIGNED NOT NULL,
  voucher_id VARCHAR(120) NULL,
  autorizacion VARCHAR(60) NULL,
  ultimos4 CHAR(4) NULL,
  marca_tarjeta VARCHAR(32) NULL,
  terminal_id BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_comprobante_pago (pago_id),
  KEY ix_comp_terminal (terminal_id),
  CONSTRAINT fk_comp_pago FOREIGN KEY (pago_id)
    REFERENCES pago(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_comp_terminal FOREIGN KEY (terminal_id)
    REFERENCES terminal(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS documentacion_pago (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pago_id BIGINT UNSIGNED NOT NULL,
  url VARCHAR(512) NULL,
  tipo_mime VARCHAR(100) NULL,
  notas VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_doc_pago (pago_id),
  CONSTRAINT fk_doc_pago FOREIGN KEY (pago_id) REFERENCES pago(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS propina (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  monto DECIMAL(12,2) NOT NULL,
  registrado_por_usuario_id BIGINT UNSIGNED NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_propina_orden (orden_id),
  KEY ix_propina_usuario (registrado_por_usuario_id),
  CONSTRAINT fk_propina_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_propina_usuario FOREIGN KEY (registrado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS movimiento_caja (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  caja_cierre_id BIGINT UNSIGNED NOT NULL,
  tipo ENUM('ingreso','retiro','ajuste') NOT NULL,
  monto DECIMAL(12,2) NOT NULL,
  referencia VARCHAR(160) NULL,
  creado_por_usuario_id BIGINT UNSIGNED NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_movcaja_caja (caja_cierre_id, creado_en),
  KEY ix_movcaja_usuario (creado_por_usuario_id),
  CONSTRAINT fk_movcaja_caja FOREIGN KEY (caja_cierre_id) REFERENCES caja_cierre(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_movcaja_usuario FOREIGN KEY (creado_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 9: Alertas internas
-- ============================================
CREATE TABLE IF NOT EXISTS alerta (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_origen_id BIGINT UNSIGNED NOT NULL,
  usuario_destino_id BIGINT UNSIGNED NULL,
  mesa_id BIGINT UNSIGNED NULL,
  orden_id BIGINT UNSIGNED NULL,
  tipo ENUM('sistema','operacion','inventario','mensaje') NOT NULL DEFAULT 'mensaje',
  mensaje VARCHAR(255) NOT NULL,
  metadata JSON NULL,
  leida TINYINT(1) NOT NULL DEFAULT 0,
  leido_por_usuario_id BIGINT UNSIGNED NULL,
  leido_en TIMESTAMP NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_alerta_destino (usuario_destino_id, leida, creado_en),
  KEY ix_alerta_mesa (mesa_id),
  KEY ix_alerta_orden (orden_id),
  KEY ix_alerta_leido_por (leido_por_usuario_id),
  CONSTRAINT fk_alerta_origen FOREIGN KEY (usuario_origen_id) REFERENCES usuario(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_alerta_destino FOREIGN KEY (usuario_destino_id) REFERENCES usuario(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_alerta_mesa FOREIGN KEY (mesa_id) REFERENCES mesa(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_alerta_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 10: Conteo de inventario (manual)
-- ============================================
CREATE TABLE IF NOT EXISTS conteo_inventario (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  fecha DATE NOT NULL,
  responsable_usuario_id BIGINT UNSIGNED NOT NULL,
  estado ENUM('en_proceso','cerrado','aprobado') NOT NULL DEFAULT 'en_proceso',
  notas VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_conteo_fecha (fecha),
  KEY ix_conteo_responsable (responsable_usuario_id),
  CONSTRAINT fk_conteo_responsable FOREIGN KEY (responsable_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS conteo_inventario_item (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  conteo_id BIGINT UNSIGNED NOT NULL,
  inventario_item_id BIGINT UNSIGNED NOT NULL,
  cantidad_contada DECIMAL(12,3) NOT NULL,
  observaciones VARCHAR(255) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_conteo_item (conteo_id, inventario_item_id),
  KEY ix_cii_conteo (conteo_id),
  KEY ix_cii_item (inventario_item_id),
  CONSTRAINT fk_cii_conteo FOREIGN KEY (conteo_id) REFERENCES conteo_inventario(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_cii_item FOREIGN KEY (inventario_item_id) REFERENCES inventario_item(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ETAPA 11: Comandas e impresión
-- ============================================
CREATE TABLE IF NOT EXISTS comanda_impresion (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NULL,
  exito TINYINT(1) NOT NULL DEFAULT 1,
  mensaje_error VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_comanda_orden (orden_id, creado_en),
  KEY ix_comanda_usuario (usuario_id),
  CONSTRAINT fk_comanda_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_comanda_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bitacora_impresion (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NULL,
  exito TINYINT(1) NOT NULL DEFAULT 1,
  mensaje_error VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_bitacora_orden (orden_id, creado_en),
  KEY ix_bitacora_usuario (usuario_id),
  CONSTRAINT fk_bitacora_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_bitacora_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- ETAPA 12: Agregar columnas adicionales si no existen
-- ============================================
-- Agregar columna password a usuario si no existe
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS password VARCHAR(255) NULL AFTER password_hash;

-- Agregar columna telefono a usuario si no existe
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS telefono VARCHAR(40) NULL AFTER username;

-- Agregar columna ultimo_acceso a usuario si no existe
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS ultimo_acceso TIMESTAMP NULL AFTER activo;

-- Agregar columna password_actualizada_por_usuario_id a usuario si no existe
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS password_actualizada_por_usuario_id BIGINT UNSIGNED NULL AFTER password_actualizada_en;

-- Agregar columna tiempo_estimado_preparacion a orden si no existe
ALTER TABLE orden ADD COLUMN IF NOT EXISTS tiempo_estimado_preparacion INT UNSIGNED NULL AFTER propina_sugerida;

-- Agregar columna cliente_telefono a orden si no existe
ALTER TABLE orden ADD COLUMN IF NOT EXISTS cliente_telefono VARCHAR(40) NULL AFTER cliente_nombre;

-- Agregar columna metadata a alerta si no existe
ALTER TABLE alerta ADD COLUMN IF NOT EXISTS metadata JSON NULL AFTER mensaje;

-- Agregar campos de lectura a alerta si no existen
ALTER TABLE alerta ADD COLUMN IF NOT EXISTS leido_por_usuario_id BIGINT UNSIGNED NULL AFTER leida;
ALTER TABLE alerta ADD COLUMN IF NOT EXISTS leido_en TIMESTAMP NULL AFTER leido_por_usuario_id;

-- Agregar campos de revisión a caja_cierre si no existen (para módulo de cierres)
ALTER TABLE caja_cierre ADD COLUMN IF NOT EXISTS estado VARCHAR(20) NOT NULL DEFAULT 'pending' AFTER notas;
ALTER TABLE caja_cierre ADD COLUMN IF NOT EXISTS revisado_por_usuario_id BIGINT UNSIGNED NULL AFTER estado;
ALTER TABLE caja_cierre ADD COLUMN IF NOT EXISTS revisado_en TIMESTAMP NULL AFTER revisado_por_usuario_id;
ALTER TABLE caja_cierre ADD COLUMN IF NOT EXISTS comentario_revision TEXT NULL AFTER revisado_en;

-- Agregar constraint único a caja_cierre.fecha si no existe
ALTER TABLE caja_cierre ADD UNIQUE KEY IF NOT EXISTS ux_caja_fecha (fecha);

-- ============================================
-- ETAPA 12b: Tablas de configuración e impresoras
-- ============================================
CREATE TABLE IF NOT EXISTS configuracion (
  id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  iva_habilitado TINYINT(1) NOT NULL DEFAULT 0,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO configuracion (id, iva_habilitado)
SELECT 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM configuracion WHERE id = 1);

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
-- ETAPA 13: Datos iniciales (Seeds)
-- ============================================

-- Roles
INSERT IGNORE INTO rol (id, nombre, descripcion) VALUES
  (1, 'administrador', 'Acceso total al sistema'),
  (2, 'cajero', 'Gestión de caja y pagos'),
  (3, 'capitan', 'Coordinación de sala'),
  (4, 'mesero', 'Toma de órdenes'),
  (5, 'cocinero', 'Gestión de cocina y KDS');

-- Permisos
INSERT IGNORE INTO permiso (nombre, descripcion) VALUES
  ('ver_caja', 'Puede ver módulo de caja'),
  ('cerrar_caja', 'Puede ejecutar cierre de caja'),
  ('editar_menu', 'Puede administrar catálogo de productos'),
  ('ver_reportes', 'Puede ver reportes del sistema'),
  ('gestionar_usuarios', 'Puede gestionar usuarios y roles');

-- Estados de mesa
INSERT IGNORE INTO estado_mesa (nombre, descripcion) VALUES
  ('LIBRE', 'Disponible para asignar'),
  ('OCUPADA', 'Con comensales'),
  ('RESERVADA', 'Asignada por reserva'),
  ('EN_LIMPIEZA', 'En servicio de limpieza');

-- Estados de orden
INSERT IGNORE INTO estado_orden (nombre, descripcion) VALUES
  ('abierta', 'Orden abierta en proceso'),
  ('en_preparacion', 'En preparación por cocina'),
  ('listo', 'Pedido listo para servir'),
  ('listo_para_recoger', 'Pedido para llevar listo'),
  ('pagada', 'Pagada y cerrada'),
  ('cerrada', 'Cerrada / finalizada'),
  ('cancelada', 'Cancelada');

-- Formas de pago
INSERT IGNORE INTO forma_pago (nombre, descripcion) VALUES
  ('efectivo', 'Pago en efectivo'),
  ('tarjeta_debito', 'Tarjeta de débito'),
  ('tarjeta_credito', 'Tarjeta de crédito'),
  ('transferencia', 'Transferencia bancaria');

-- Asignación inicial de permisos a roles (para que el CRUD de roles funcione con datos base)
INSERT IGNORE INTO rol_permiso (rol_id, permiso_id)
SELECT 1, p.id FROM permiso p;

INSERT IGNORE INTO rol_permiso (rol_id, permiso_id)
SELECT 2, p.id FROM permiso p WHERE p.nombre IN ('ver_caja', 'cerrar_caja');

-- Usuario administrador por defecto (contraseña: Demo1234)
INSERT IGNORE INTO usuario (id, nombre, username, telefono, password_hash, password, activo, password_actualizada_en, creado_en, actualizado_en) VALUES
  (1, 'Administrador', 'admin', '555-0001', '$2b$10$iQvlAwdWmMI5dH3TZzIvee20rcQMjv9Me4l4FIAwGZY9yg6543WaK', 'Demo1234', 1, NOW(), NOW(), NOW());

-- Asignar rol de administrador al usuario admin
INSERT IGNORE INTO usuario_rol (usuario_id, rol_id) VALUES (1, 1);

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
SELECT 'Base de datos comandero creada exitosamente' AS mensaje;
