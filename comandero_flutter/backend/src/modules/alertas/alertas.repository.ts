import type { RowDataPacket, ResultSetHeader } from 'mysql2';
import { pool } from '../../db/pool.js';
import type { AlertaDB, AlertaPayload } from './alertas.types.js';

interface AlertaRow extends RowDataPacket {
  id: number;
  tipo: string;
  mensaje: string;
  orden_id: number | null;
  mesa_id: number | null;
  usuario_origen_id: number;
  usuario_destino_id: number | null;
  leida: boolean;
  creado_en: Date;
  metadata?: string | null; // JSON string
}

/**
 * Crea una nueva alerta en la base de datos
 * El schema actual de la tabla alerta tiene:
 * - tipo ENUM('sistema','operacion','inventario','mensaje')
 * - metadata JSON (opcional) para guardar información adicional como prioridad
 */
export const crearAlerta = async (
  params: {
    tipo: 'sistema' | 'operacion' | 'inventario' | 'mensaje';
    mensaje: string;
    ordenId: number | null;
    mesaId: number | null;
    usuarioOrigenId: number;
    usuarioDestinoId?: number | null;
    metadata?: Record<string, unknown> | null;
  }
): Promise<number> => {
  // Convertir metadata a JSON string si existe
  const metadataJson = params.metadata ? JSON.stringify(params.metadata) : null;
  
  // Intentar insertar con metadata si existe, sino usar campos básicos
  // Si la columna metadata no existe, MySQL simplemente la ignorará
  try {
    if (metadataJson) {
      // Intentar insertar con metadata
      const [result] = await pool.query<ResultSetHeader>(
        `
        INSERT INTO alerta (
          tipo, mensaje, orden_id, mesa_id, usuario_origen_id, usuario_destino_id, leida, creado_en, metadata
        ) VALUES (?, ?, ?, ?, ?, ?, 0, NOW(), ?)
        `,
        [
          params.tipo,
          params.mensaje,
          params.ordenId,
          params.mesaId,
          params.usuarioOrigenId,
          params.usuarioDestinoId || null,
          metadataJson
        ]
      );
      return result.insertId;
    } else {
      // Insertar sin metadata
      const [result] = await pool.query<ResultSetHeader>(
        `
        INSERT INTO alerta (
          tipo, mensaje, orden_id, mesa_id, usuario_origen_id, usuario_destino_id, leida, creado_en
        ) VALUES (?, ?, ?, ?, ?, ?, 0, NOW())
        `,
        [
          params.tipo,
          params.mensaje,
          params.ordenId,
          params.mesaId,
          params.usuarioOrigenId,
          params.usuarioDestinoId || null
        ]
      );
      return result.insertId;
    }
  } catch (error: any) {
    // Si hay error por columna metadata no existente, intentar sin metadata
    if (error.code === 'ER_BAD_FIELD_ERROR' && metadataJson) {
      const [result] = await pool.query<ResultSetHeader>(
        `
        INSERT INTO alerta (
          tipo, mensaje, orden_id, mesa_id, usuario_origen_id, usuario_destino_id, leida, creado_en
        ) VALUES (?, ?, ?, ?, ?, ?, 0, NOW())
        `,
        [
          params.tipo,
          params.mensaje,
          params.ordenId,
          params.mesaId,
          params.usuarioOrigenId,
          params.usuarioDestinoId || null
        ]
      );
      return result.insertId;
    }
    throw error;
  }
};

interface AlertaRowWithMesa extends AlertaRow {
  mesa_codigo?: string | null;
}

/**
 * Obtiene alertas no leídas para un usuario o rol.
 * Incluye mesa_codigo (número visible de mesa) vía JOIN para mostrar siempre
 * la mesa correcta en cocinero/capitán, nunca el mesa_id (ID de BD).
 */
export const obtenerAlertasNoLeidas = async (
  usuarioId?: number,
  rol?: string,
  tipoFiltro?: string | null
): Promise<AlertaDB[]> => {
  // No usar a.metadata: la columna puede no existir en la BD (Unknown column 'a.metadata').
  let query = `
    SELECT a.id, a.tipo, a.mensaje, a.orden_id, a.mesa_id, a.usuario_origen_id, a.usuario_destino_id, a.leida, a.creado_en,
           m.codigo AS mesa_codigo
    FROM alerta a
    LEFT JOIN mesa m ON m.id = a.mesa_id
    WHERE a.leida = 0
  `;
  const params: unknown[] = [];

  if (usuarioId) {
    query += ' AND a.usuario_origen_id != ?';
    params.push(usuarioId);
  }

  // Filtrar por tipo si se especifica (útil para meseros que solo necesitan alerta.cocina)
  if (tipoFiltro) {
    query += ' AND a.tipo = ?';
    params.push(tipoFiltro);
  }

  query += ' ORDER BY a.creado_en DESC LIMIT 50';

  const [rows] = await pool.query<AlertaRowWithMesa[]>(query, params);

  return rows.map((row) => {
    const alerta: any = {
      id: row.id,
      tipo: row.tipo,
      mensaje: row.mensaje,
      ordenId: row.orden_id,
      mesaId: row.mesa_id,
      mesaCodigo: row.mesa_codigo ?? null,
      creadoPorUsuarioId: row.usuario_origen_id,
      leido: Boolean(row.leida),
      creadoEn: row.creado_en
    };
    return alerta;
  });
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

