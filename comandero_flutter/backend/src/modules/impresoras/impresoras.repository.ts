import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';
import type { DocumentType, PaperWidth, PrinterConfigEntry } from '../../config/printers.config.js';
import { normalizePaperWidth } from '../../config/printers.config.js';

export type TipoImpresora = 'usb' | 'tcp' | 'bluetooth' | 'simulation';

interface ImpresoraRow extends RowDataPacket {
  id: number;
  nombre: string;
  tipo: string;
  device: string | null;
  host: string | null;
  port: number | null;
  paper_width: number;
  imprime_ticket: number;
  imprime_comanda: number;
  orden: number;
  activo: number;
  marca_modelo: string | null;
}

export interface Impresora {
  id: number;
  nombre: string;
  tipo: TipoImpresora;
  device: string | null;
  host: string | null;
  port: number | null;
  paperWidth: PaperWidth;
  imprimeTicket: boolean;
  imprimeComanda: boolean;
  orden: number;
  activo: boolean;
  marcaModelo: string | null;
}

function rowToImpresora(row: ImpresoraRow): Impresora {
  return {
    id: row.id,
    nombre: row.nombre,
    tipo: row.tipo as TipoImpresora,
    device: row.device ?? null,
    host: row.host ?? null,
    port: row.port ?? null,
    paperWidth: normalizePaperWidth(row.paper_width),
    imprimeTicket: Boolean(row.imprime_ticket),
    imprimeComanda: Boolean(row.imprime_comanda),
    orden: row.orden,
    activo: Boolean(row.activo),
    marcaModelo: row.marca_modelo ?? null,
  };
}

export async function listarImpresoras(): Promise<Impresora[]> {
  const [rows] = await pool.query<ImpresoraRow[]>(
    'SELECT * FROM impresora ORDER BY orden ASC, id ASC'
  );
  return rows.map(rowToImpresora);
}

export async function listarImpresorasActivasParaDocumento(document: DocumentType): Promise<Impresora[]> {
  const col = document === 'ticket' ? 'imprime_ticket' : 'imprime_comanda';
  const [rows] = await pool.query<ImpresoraRow[]>(
    `SELECT * FROM impresora WHERE activo = 1 AND ${col} = 1 ORDER BY orden ASC, id ASC`
  );
  return rows.map(rowToImpresora);
}

export async function obtenerImpresoraPorId(id: number): Promise<Impresora | null> {
  const [rows] = await pool.query<ImpresoraRow[]>(
    'SELECT * FROM impresora WHERE id = ?',
    [id]
  );
  const row = rows[0];
  return row ? rowToImpresora(row) : null;
}

export interface CrearImpresoraInput {
  nombre: string;
  tipo: TipoImpresora;
  device?: string | null;
  host?: string | null;
  port?: number | null;
  paperWidth?: PaperWidth;
  imprimeTicket?: boolean;
  imprimeComanda?: boolean;
  orden?: number;
  marcaModelo?: string | null;
}

export async function crearImpresora(input: CrearImpresoraInput): Promise<number> {
  const [result] = await pool.execute<ResultSetHeader>(
    `INSERT INTO impresora (
      nombre, tipo, device, host, port, paper_width,
      imprime_ticket, imprime_comanda, orden, marca_modelo
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      input.nombre,
      input.tipo,
      input.device ?? null,
      input.host ?? null,
      input.port ?? null,
      normalizePaperWidth(input.paperWidth),
      input.imprimeTicket !== false ? 1 : 0,
      input.imprimeComanda ? 1 : 0,
      input.orden ?? 0,
      input.marcaModelo ?? null,
    ]
  );
  return result.insertId;
}

export interface ActualizarImpresoraInput {
  nombre?: string;
  tipo?: TipoImpresora;
  device?: string | null;
  host?: string | null;
  port?: number | null;
  paperWidth?: PaperWidth;
  imprimeTicket?: boolean;
  imprimeComanda?: boolean;
  orden?: number;
  activo?: boolean;
  marcaModelo?: string | null;
}

export async function actualizarImpresora(id: number, input: ActualizarImpresoraInput): Promise<boolean> {
  const sets: string[] = [];
  const values: unknown[] = [];
  if (input.nombre !== undefined) { sets.push('nombre = ?'); values.push(input.nombre); }
  if (input.tipo !== undefined) { sets.push('tipo = ?'); values.push(input.tipo); }
  if (input.device !== undefined) { sets.push('device = ?'); values.push(input.device); }
  if (input.host !== undefined) { sets.push('host = ?'); values.push(input.host); }
  if (input.port !== undefined) { sets.push('port = ?'); values.push(input.port); }
  if (input.paperWidth !== undefined) { sets.push('paper_width = ?'); values.push(normalizePaperWidth(input.paperWidth)); }
  if (input.imprimeTicket !== undefined) { sets.push('imprime_ticket = ?'); values.push(input.imprimeTicket ? 1 : 0); }
  if (input.imprimeComanda !== undefined) { sets.push('imprime_comanda = ?'); values.push(input.imprimeComanda ? 1 : 0); }
  if (input.orden !== undefined) { sets.push('orden = ?'); values.push(input.orden); }
  if (input.activo !== undefined) { sets.push('activo = ?'); values.push(input.activo ? 1 : 0); }
  if (input.marcaModelo !== undefined) { sets.push('marca_modelo = ?'); values.push(input.marcaModelo); }
  if (sets.length === 0) return true;
  values.push(id);
  const [result] = await pool.execute<ResultSetHeader>(
    `UPDATE impresora SET ${sets.join(', ')} WHERE id = ?`,
    values
  );
  return (result.affectedRows ?? 0) > 0;
}

export async function eliminarImpresora(id: number): Promise<boolean> {
  const [result] = await pool.execute<ResultSetHeader>('DELETE FROM impresora WHERE id = ?', [id]);
  return (result.affectedRows ?? 0) > 0;
}

/** Convierte impresoras de la BD al formato que usa el sistema de impresión (tickets/comandas). Bluetooth se mapea a usb. */
export async function getImpresorasAsPrinterConfig(document: DocumentType): Promise<PrinterConfigEntry[]> {
  const list = await listarImpresorasActivasParaDocumento(document);
  return list.map((i): PrinterConfigEntry => {
    const type = i.tipo === 'bluetooth' ? 'usb' : i.tipo === 'simulation' ? 'simulation' : i.tipo === 'tcp' ? 'tcp' : 'usb';
    const documents: DocumentType[] = [];
    if (i.imprimeTicket) documents.push('ticket');
    if (i.imprimeComanda) documents.push('comanda');
    return {
      id: String(i.id),
      name: i.nombre,
      type,
      documents,
      paperWidth: i.paperWidth,
      device: i.device ?? undefined,
      host: i.host ?? undefined,
      port: i.port ?? undefined,
    };
  });
}
