import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';

export type TipoDocumentoCola = 'comanda' | 'ticket';
export type EstadoCola = 'pendiente' | 'impreso' | 'error';

export interface ColaImpresionRow extends RowDataPacket {
  id: number;
  impresora_id: number;
  tipo_documento: string;
  referencia_id: number | null;
  contenido: string;
  estado: string;
  mensaje_error: string | null;
  creado_en: Date;
  impreso_en: Date | null;
}

export interface JobCola {
  id: number;
  impresoraId: number;
  tipoDocumento: TipoDocumentoCola;
  referenciaId: number | null;
  contenido: string;
  estado: EstadoCola;
  mensajeError: string | null;
  creadoEn: Date;
  impresoEn: Date | null;
}

function rowToJob(row: ColaImpresionRow): JobCola {
  return {
    id: row.id,
    impresoraId: row.impresora_id,
    tipoDocumento: row.tipo_documento as TipoDocumentoCola,
    referenciaId: row.referencia_id,
    contenido: row.contenido,
    estado: row.estado as EstadoCola,
    mensajeError: row.mensaje_error,
    creadoEn: row.creado_en,
    impresoEn: row.impreso_en,
  };
}

/** Encolar un trabajo de impresión (para impresoras USB remotas). */
export async function encolarImpresion(
  impresoraId: number,
  tipoDocumento: TipoDocumentoCola,
  contenido: string,
  referenciaId: number | null
): Promise<number> {
  const [result] = await pool.execute<ResultSetHeader>(
    `INSERT INTO cola_impresion (impresora_id, tipo_documento, referencia_id, contenido, estado)
     VALUES (?, ?, ?, ?, 'pendiente')`,
    [impresoraId, tipoDocumento, referenciaId, contenido]
  );
  return result.insertId;
}

/** Listar trabajos pendientes para una impresora (para el agente local). */
export async function listarPendientesPorImpresora(impresoraId: number): Promise<JobCola[]> {
  const [rows] = await pool.query<ColaImpresionRow[]>(
    `SELECT id, impresora_id, tipo_documento, referencia_id, contenido, estado, mensaje_error, creado_en, impreso_en
     FROM cola_impresion
     WHERE impresora_id = ? AND estado = 'pendiente'
     ORDER BY id ASC`,
    [impresoraId]
  );
  return rows.map(rowToJob);
}

/** Obtener un trabajo por ID (para validar que pertenece a la impresora). */
export async function obtenerJobPorId(id: number): Promise<JobCola | null> {
  const [rows] = await pool.query<ColaImpresionRow[]>(
    'SELECT id, impresora_id, tipo_documento, referencia_id, contenido, estado, mensaje_error, creado_en, impreso_en FROM cola_impresion WHERE id = ?',
    [id]
  );
  const row = rows[0];
  return row ? rowToJob(row) : null;
}

/** Marcar un trabajo como impreso. */
export async function marcarImpreso(id: number): Promise<boolean> {
  const [result] = await pool.execute<ResultSetHeader>(
    `UPDATE cola_impresion SET estado = 'impreso', impreso_en = CURRENT_TIMESTAMP(3) WHERE id = ? AND estado = 'pendiente'`,
    [id]
  );
  return result.affectedRows > 0;
}

/** Marcar un trabajo como error. */
export async function marcarError(id: number, mensaje: string): Promise<boolean> {
  const [result] = await pool.execute<ResultSetHeader>(
    `UPDATE cola_impresion SET estado = 'error', mensaje_error = ?, impreso_en = CURRENT_TIMESTAMP(3) WHERE id = ? AND estado = 'pendiente'`,
    [mensaje.substring(0, 500), id]
  );
  return result.affectedRows > 0;
}
