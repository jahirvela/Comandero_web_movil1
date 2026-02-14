-- Configuración del negocio (IVA y opciones futuras). Una sola fila (id=1).
-- IVA aplicable en México CDMX (16%): habilitado/deshabilitado según necesidad del cliente.
CREATE TABLE IF NOT EXISTS configuracion (
  id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  iva_habilitado TINYINT(1) NOT NULL DEFAULT 0,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar fila por defecto si no existe (IVA deshabilitado por defecto)
INSERT INTO configuracion (id, iva_habilitado)
SELECT 1, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM configuracion WHERE id = 1);
