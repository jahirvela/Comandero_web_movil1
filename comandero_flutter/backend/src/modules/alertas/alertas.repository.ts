import type { RowDataPacket, ResultSetHeader } from 'mysql2';
import { pool } from '../../db/pool.js';
import type { AlertaDB, AlertaPayload } from './alertas.types.js';

interface AlertaRow extends RowDataPacket {
  id: number;
  tipo: string;
  mensaje: string;
  orden_id: number | null;
  mesa_id: number | null;
  producto_id: number | null;
  prioridad: string;
  estacion: string | null;
  usuario_origen_id: number;
  usuario_destino_id: number | null;
  leida: boolean;
  leido_por_usuario_id: number | null;
  leido_en: Date | null;
  creado_en: Date;
}

/**
 * Crea una nueva alerta en la base de datos
 */
export const crearAlerta = async (payload: AlertaPayload, usuarioId: number): Promise<number> => {
  const [result] = await pool.query<ResultSetHeader>(
    `
    INSERT INTO alerta (
      tipo, mensaje, orden_id, mesa_id, producto_id,
      prioridad, estacion, usuario_origen_id, leida, creado_en
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, NOW())
    `,
    [
      payload.tipo,
      payload.mensaje,
      payload.ordenId || null,
      payload.mesaId || null,
      payload.productoId || null,
      payload.prioridad || 'media',
      payload.estacion || null,
      usuarioId
    ]
  );

  return result.insertId;
};

/**
 * Obtiene alertas no leídas para un usuario o rol
 */
export const obtenerAlertasNoLeidas = async (
  usuarioId?: number,
  rol?: string,
  tipoFiltro?: string | null
): Promise<AlertaDB[]> => {
  let query = `
    SELECT * FROM alerta
    WHERE leida = 0
  `;
  const params: unknown[] = [];

  if (usuarioId) {
    query += ' AND usuario_origen_id != ?';
    params.push(usuarioId);
  }

  // Filtrar por tipo si se especifica (útil para meseros que solo necesitan alerta.cocina)
  if (tipoFiltro) {
    query += ' AND tipo = ?';
    params.push(tipoFiltro);
  }

  query += ' ORDER BY creado_en DESC LIMIT 50';

  const [rows] = await pool.query<AlertaRow[]>(query, params);

  return rows.map((row) => ({
    id: row.id,
    tipo: row.tipo,
    mensaje: row.mensaje,
    ordenId: row.orden_id,
    mesaId: row.mesa_id,
    productoId: row.producto_id,
    prioridad: row.prioridad,
    estacion: row.estacion,
    creadoPorUsuarioId: row.usuario_origen_id,
    leido: Boolean(row.leida),
    leidoPorUsuarioId: row.leido_por_usuario_id,
    leidoEn: row.leido_en,
    creadoEn: row.creado_en
  }));
};

/**
 * Marca una alerta como leída
 */
export const marcarAlertaLeida = async (alertaId: number, usuarioId: number): Promise<void> => {
  await pool.query(
    `
    UPDATE alerta
    SET leida = 1, leido_por_usuario_id = ?, leido_en = NOW()
    WHERE id = ?
    `,
    [usuarioId, alertaId]
  );
};

/**
 * Marca todas las alertas no leídas como leídas para un usuario
 * Si se especifica un tipo, solo marca alertas de ese tipo
 */
export const marcarTodasLasAlertasComoLeidas = async (
  usuarioId: number,
  tipoFiltro?: string | null
): Promise<number> => {
  let query = `
    UPDATE alerta
    SET leida = 1, leido_por_usuario_id = ?, leido_en = NOW()
    WHERE leida = 0 AND usuario_origen_id != ?
  `;
  const params: unknown[] = [usuarioId, usuarioId];

  if (tipoFiltro) {
    query += ' AND tipo = ?';
    params.push(tipoFiltro);
  }

  const [result] = await pool.query<ResultSetHeader>(query, params);
  return result.affectedRows;
};

