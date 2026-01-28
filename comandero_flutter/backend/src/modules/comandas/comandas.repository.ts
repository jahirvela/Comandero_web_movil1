import type { RowDataPacket, ResultSetHeader } from 'mysql2';
import { pool } from '../../db/pool.js';
import { logger } from '../../config/logger.js';

interface ComandaImpresionRow extends RowDataPacket {
  id: number;
  orden_id: number;
  impreso_automaticamente: boolean;
  impreso_por_usuario_id: number | null;
  es_reimpresion: boolean;
  creado_en: Date;
}

/**
 * Verifica si una comanda ya fue impresa
 */
export const verificarComandaImpresa = async (ordenId: number): Promise<boolean> => {
  try {
    const [rows] = await pool.query<ComandaImpresionRow[]>(
      `SELECT id FROM comanda_impresion 
       WHERE orden_id = ? 
       AND impreso_automaticamente = 1
       LIMIT 1`,
      [ordenId]
    );
    return rows.length > 0;
  } catch (error: any) {
    // Si la tabla no existe, retornar false (no impresa)
    if (error.code === 'ER_NO_SUCH_TABLE') {
      logger.debug('Tabla comanda_impresion no existe, asumiendo que no está impresa');
      return false;
    }
    logger.warn({ err: error, ordenId }, 'Error al verificar si comanda está impresa');
    return false;
  }
};

/**
 * Marca una comanda como impresa
 */
export const marcarComandaImpresa = async (
  ordenId: number,
  impresoPorUsuarioId: number | null = null,
  esReimpresion: boolean = false
): Promise<void> => {
  try {
    await pool.query<ResultSetHeader>(
      `INSERT INTO comanda_impresion 
       (orden_id, impreso_automaticamente, impreso_por_usuario_id, es_reimpresion, creado_en)
       VALUES (?, ?, ?, ?, NOW())`,
      [
        ordenId,
        impresoPorUsuarioId === null ? 1 : 0, // Si no hay usuario, es automática
        impresoPorUsuarioId,
        esReimpresion ? 1 : 0
      ]
    );
    logger.info(
      { ordenId, impresoPorUsuarioId, esReimpresion },
      '✅ Comanda marcada como impresa'
    );
  } catch (error: any) {
    // Si la tabla no existe, intentar crearla
    if (error.code === 'ER_NO_SUCH_TABLE') {
      logger.warn('Tabla comanda_impresion no existe, creándola...');
      await crearTablaComandaImpresion();
      // Reintentar después de crear la tabla
      await marcarComandaImpresa(ordenId, impresoPorUsuarioId, esReimpresion);
      return;
    }
    logger.error({ err: error, ordenId }, 'Error al marcar comanda como impresa');
    throw error;
  }
};

/**
 * Crea la tabla comanda_impresion si no existe
 */
const crearTablaComandaImpresion = async (): Promise<void> => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS comanda_impresion (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        orden_id BIGINT UNSIGNED NOT NULL,
        impreso_automaticamente BOOLEAN NOT NULL DEFAULT 1,
        impreso_por_usuario_id BIGINT UNSIGNED NULL,
        es_reimpresion BOOLEAN NOT NULL DEFAULT 0,
        creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        KEY ix_comanda_orden (orden_id),
        KEY ix_comanda_usuario (impreso_por_usuario_id),
        KEY ix_comanda_automatica (impreso_automaticamente),
        CONSTRAINT fk_comanda_orden FOREIGN KEY (orden_id) REFERENCES orden(id) ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT fk_comanda_usuario FOREIGN KEY (impreso_por_usuario_id) REFERENCES usuario(id) ON UPDATE CASCADE ON DELETE SET NULL
      ) ENGINE=InnoDB
    `);
    logger.info('✅ Tabla comanda_impresion creada exitosamente');
  } catch (error: any) {
    logger.error({ err: error }, 'Error al crear tabla comanda_impresion');
    throw error;
  }
};

